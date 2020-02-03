/*
  Copyright 2017 Bprotocol Foundation, 2019 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.5.9;

import "../interfaces/IStructs.sol";
import "./LibFixedMath.sol";
import "./LibBondingCurve.sol";


library LibPriceDiscovery {

    using LibFixedMath for int256;

    // Fixed-point numbers used by this library.
    int256 private constant ONE = int256(0x0000000000000000000000000000000080000000000000000000000000000000);

    // The best price can only diverge by 5% from the max price. We store 95% to simplify computation.
    int256 private constant MAX_PRICE_DIVERGENCE = int256(0x0000000000000000000000000000000079999999999999999999999999999999); // 0.95

    // The max percent error is 10%. This value is tao in the Whitepaper and must be in the range [0..1].
    int256 private constant MAX_PERCENT_ERROR = int256(0x000000000000000000000000000000000ccccccccccccccccccccccccccccccc); // 0.1

    event VALUE(
        string description,
        int256 val
    );

    function computeBestPrice(
        IStructs.BondingCurve memory curve,
        int256 maxMakerPrice,
        int256 minMakerPrice,
        int256 takerAssetAmount,
        int256 fee
    )
        internal
        // pure
        returns (int256 bestMakerPrice)
    {
        // The best price is discovered by solving the recursive price function
        // defined in Section 4.2 of the Whitepaper. This function is the
        // first derivative of the Bonding Curve, and is rearranged into a
        // form that allows us to run a series of root-finding algorithms
        // that iteratively find solve the price function. In this form,
        // we define a "root" as the ratio bestPrice/maxMakerPrice.
        int256 root = findBestRoot(
            curve,
            maxMakerPrice,
            minMakerPrice,
            takerAssetAmount,
            fee
        );

        // Uncover the best maker price.
        bestMakerPrice = root.mul(maxMakerPrice);

        // The best Price must be in the range [minMakerPrice..maxMakerPrice].
        if (bestMakerPrice <= 0)  {
            // Sanity check. If best Price is <= 0 then the computation failed.
            revert('Internal Error. Best Price cannot be <= 0.');
        } else if (bestMakerPrice < maxMakerPrice.mul(MAX_PRICE_DIVERGENCE)) {
            revert('Internal Error. Best Maker Price deviated more than 5% from the Max Maker Price.');
        } else if (bestMakerPrice < minMakerPrice) { // do we really want this?
            bestMakerPrice = minMakerPrice;
        } else if (bestMakerPrice > maxMakerPrice) {
            bestMakerPrice = maxMakerPrice;
        }
    }

    function isRootPrecise(
        int256 rl,
        int256 rh,
        int256 fee
    )
        internal

        returns (bool shouldImprovePrecision)
    {
        // The true root lies between [rl..rh].
        // Once the difference is less than a certain threshold,
        // we consider it to be precise enough.
        int256 range = rh.sub(rl);

        // The precision threshold is somewhat arbitrary. We want to ensure that
        // we have high precision for small trades, in which case rh is close to 1
        // and this reduces to MAX_PERCENT_ERROR * fee. As trades increase in size,
        // the threshold also increases (which means we demand less precision).
        int256 threshold = MAX_PERCENT_ERROR.mul(fee.add(ONE).sub(rh));

        // Iff true then enough precision has been reached. Either rl or rh
        // would be representative of the true root. The algorithm
        // chooses rl (the lower price) because it is cheaper for the contract.
        return range <= threshold;
    }

    /// @dev Computes the root that corresponds to the best price on the bonding curve.
    ///      Note that the root is computed on a transposition of the Price Curve,
    ///      which is the first derivative of the Bonding Curve. In this transposed form,
    ///      we define a "root" as the ratio bestPrice/maxMakerPrice. The function's form
    ///      is defined recursively as "root = f(root)", which we solve using numerical methods.
    ///
    ///      This function implements the Bracketing Root-Finding Algorithm defined in the whitepaper,
    ///      which sarts with an initial guess at approximately [minMakerPrice, maxMakerPrice]
    ///      and iteratively closes in on the correct value that satisfies `root = f(root)`.
    ///
    ///      Three root-finding algorithms are applied: Newton's Method, Secant Method and Bisection.
    ///      Combining the three methods achieves a high-precision and fail-safe algorithm.
    ///      See Section 4.3 of the Whitepaper for more implementation details.
    function findBestRoot(
        IStructs.BondingCurve memory curve,
        int256 maxMakerPrice,
        int256 minMakerPrice,
        int256 takerAssetAmount,
        int256 fee
    )
        internal
        returns (int256)
    {
        // Define Constants.
        // This is computed as k8 in the Whitepaper.
        int256 k1 = curve.xReserve.mul(
            maxMakerPrice
            .mul(takerAssetAmount)
            .div(
                curve.xReserve
                .mul(curve.yReserve)
                .add(curve.yReserve.mul(takerAssetAmount))
            )
        );

        // This is computed as k12 in the Whitepaper.
        int256 k2 = curve.xReserve.div(
            curve.xReserve.add(takerAssetAmount)
        );

        // Compute initial lower bound root.
        int256 rl = minMakerPrice.div(maxMakerPrice);

        // Compute an initial upper-bound of the root using Newton's Method.
        // We use k2/k1 as an initial lower-bound, which is just a safety-guard
        // in case the taker buys too much: this root reflects the taker buying
        // the entire maker reserve.
        //  Note that the root is computed on a transposition of the Price Curve,
        //  which is the first derivative of the Bonding Curve.  In this transposed form,
        //  we define a "root" as the ratio bestPrice/maxMakerPrice. Observe the equation
        //  at "Step 2" in the whitepaper's Bracketing algorithm, accompanied by
        //  the visualization in Figure 4 of the whitepaper.
        int256 rh = findRootNewtonsMethod(
            curve,
            k2.div(k1),
            ONE,
            ONE,
            k1,
            k2
        );

        // Check if the root estimate is precise enough.
        // This will be true in the majority of cases. When a trade
        // is very small then we will demand more precision. Similarly,
        // when a trade is very large, we are more likely to encounter
        // a failure scenario of Newton's Method to compute the upper-bound above:
        // In such a case, the tangent on the transposed price function would be ~= 0, yielding a
        // price that is infinitely high; we handle this by recomputing using Secant/Bisection (below).
        if (isRootPrecise(rl, rh, fee)) {
            return rl;
        }

        // Comptute the point on the transposed price corve that corresponds to the lower-bound root, rl.
        // We then use the tangent line at (rl, yl) along with Newton's method to update our guess for the
        // upper-bound root, rh.
        int256 yl = computePointOnTransposedPriceCurve(curve, rl);
        rh = findRootNewtonsMethod(
            curve,
            rh,
            rl,
            yl,
            k1,
            k2
        );

        // Check if the root estimate is precise enough, after running
        // the additional iteration of Newton's Method.
        if (isRootPrecise(rl, rh, fee)) {
            return rl;
        }

        int256 slippage = curve.slippage;

        int256 yh;
        (rl, rh, yl, yh) = _computeStep4(
            rl,
            rh,
            k1,
            k2,
            yl,
            slippage
        );

        emit VALUE("rl after step 4", rl);
        emit VALUE("rh after step 4", rh);
        emit VALUE("yl after step 4", yl);
        emit VALUE("yh after step 4", yh);

        if (isRootPrecise(rl, rh, fee)) {
            return rl;
        }

        rl = _computeStep5(
            rl,
            rh,
            yl,
            yh,
            k1,
            k2
        );

        return rl;

        emit VALUE("rl after step 5", rl);
    }

    function findRootNewtonsMethod(
        IStructs.BondingCurve memory curve,
        int256 minRoot,
        int256 x,
        int256 y,
        int256 k1,
        int256 k2
    )
        internal
        pure
        returns (int256)
    {
        // Define constants.
        int256 k3 = ONE.sub(curve.slippage);

        // Construct root using Newton's Method.
        int256 n = curve.slippage
            .mul(y)
            .add(k3.mul(k2));
        int256 d = k3
            .mul(k1)
            .mul(x)
            .add(y);
        int256 root = x
            .mul(n)
            .div(d);

        return LibFixedMath.min(minRoot, root);
    }

    function computePointOnTransposedPriceCurve(
        IStructs.BondingCurve memory curve,
        int256 x
    )
        internal
        pure
        returns (int256 y)
    {
        int256 exponent = ONE.div(ONE.sub(curve.slippage));
        return x.pow(exponent);
    }

    function _computeA(int256 rl, int256 rh)
        internal
        returns (int256)
    {
        return rl.mul(LibFixedMath.toFixed(int256(4)))
            .add(rh.mul(LibFixedMath.toFixed(int256(6))))
            .div(LibFixedMath.toFixed(int256(10)));
    }

     function _computeStep4(
        int256 rl,
        int256 rh,
        int256 k1,
        int256 k2,
        int256 yl,
        int256 rhoRatio
    )
        internal

        returns (
            int256 newRl,
            int256 newRh,
            int256 newYl,
            int256 newYh
        )
    {
        // compute yBis
        int256 term1 = _computeA(rl, rh);
        int256 ratio = LibFixedMath.one().div(LibFixedMath.one().sub(rhoRatio));
        int256 yBis = term1.pow(ratio);

        //
        int256 term2 = k2.sub(k1.mul(term1));
        if (yBis <= term2) {
            newRl = term1;
            newRh = rh;
            newYl = yBis;
            newYh = rh.pow(ratio);
        } else {
            newRl = rl;
            newRh = term1;
            newYl = yl;
            newYh = yBis;
       }

       return (
           newRl,
           newRh,
           newYl,
           newYh
       );
    }

    function _computeStep5(
        int256 rl,
        int256 rh,
        int256 yl,
        int256 yh,
        int256 k1,
        int256 k2
    )
        internal

        returns (int256)
    {
        int256 term1 = yh.mul(rl)
            .sub(yl.mul(rh))
            .add(k2.mul(rh.sub(rl)));
        int256 term2 = yh
            .sub(yl)
            .add(k1.mul(rh.sub(rl)));
        int256 term3 = term1.div(term2);

        return term3 > rl
            ? term3
            : rl;
    }

}
