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


library LibBondingCurve {

    using LibFixedMath for int256;

    int256 private constant ONE = int256(0x0000000000000000000000000000000080000000000000000000000000000000);

    function createBondingCurve(
        int256 xReserve,
        int256 yReserve,
        int256 expectedPrice,
        int256 slippage
    )
        internal
        pure
        returns (IStructs.BondingCurve memory curve)
    {
        return IStructs.BondingCurve({
            xReserve: xReserve,
            yReserve: yReserve,
            expectedPrice: expectedPrice,
            slippage: slippage
        });
    }

    /// @dev Transforms the stored bonding curve for use in a trade.
    ///        This involves manipulating the expected future price
    ///        of the curve, depending on which assets is being traded.
    ///        The inputs to this function are not mutated during execution.
    function transformStoredBondingCurveForTrade(
        IStructs.BondingCurve memory curve,
        IStructs.AssetPair memory assets,
        address takerAsset
    )
        internal
        pure
        returns (IStructs.BondingCurve memory)
    {
        // The expected future price must be of Taker Assset
        // in terms of Maker Asset. The Taker Asset Amount is the
        // x-coordinate on the bonding curve (input to price). Hence,
        // if the Taker asset is the y-coordinate on the bonding curve,
        // then we must invert the expected future price.
        if (takerAsset == assets.xAsset) {
            return createBondingCurve(
                curve.xReserve,
                curve.yReserve,
                curve.expectedPrice,
                curve.slippage
            );
        } else {
            return createBondingCurve(
                curve.yReserve,
                curve.xReserve,
                ONE.div(curve.expectedPrice),
                curve.slippage
            );
        }
    }

    function transformTradeBondingCurveForStorage(
        IStructs.BondingCurve memory curve,
        IStructs.AssetPair memory assets,
        address takerAsset
    )
        internal
        pure
        returns (IStructs.BondingCurve memory)
    {
        return transformStoredBondingCurveForTrade(curve, assets, takerAsset);
    }

    /// @dev This returns the price at a specific point (a,b) on the token bond curve,
    ///      which is defined by the slope of the tangent at (a,b).
    function computeMidpointPrice(IStructs.BondingCurve memory curve)
        internal
        pure
        returns (int256 price)
    {
        int256 term1 = curve.yReserve.div(curve.expectedPrice.mul(curve.xReserve));
        int256 term2 = term1.pow(ONE.sub(curve.slippage));
        price = curve.expectedPrice.mul(term2);
    }

    /// @dev Computes the highest price to sell token `b` in the range [a, a + deltaA].
    ///
    ///      Implementation Note: This
    function computeMaximumPriceInDomain(
        IStructs.BondingCurve memory curve,
        IStructs.Domain memory domain,
        int256 midpointPrice
    )
        internal
        pure
        returns (int256 price)
    {
        int256 delta = computeOffsetToMaximumPriceInDomain(curve, domain, midpointPrice);
        int256 term1 = curve.xReserve.mul(curve.yReserve.sub(delta.mul(midpointPrice)));
        int256 term2 = curve.yReserve.mul(curve.xReserve.add(delta));
        int256 term3 = term1.div(term2);
        int256 term4 = term3.pow(ONE.sub(curve.slippage));
        int256 term5 = term4.mul(delta).div(domain.delta);
        price = term5.mul(midpointPrice);
    }

    /// @dev Computes the offset to the highest price to sell token `b` in the range [a, a + deltaA].
    ///      To do this we find the nearest local maxima, which is defined as
    ///      the point where the first derivative is zero and the second derivative
    ///      is decreasing. If this point is greater than the domain limit of `a + deltaA`,
    ///      then the maximum price is at `a + deltaA`.
    function computeOffsetToMaximumPriceInDomain(
        IStructs.BondingCurve memory curve,
        IStructs.Domain memory domain,
        int256 midpointPrice
    )
        internal
        pure
        returns (int256)
    {
        int256 a = curve.xReserve;
        int256 b = curve.yReserve;
        int256 pBarA = curve.expectedPrice;
        int256 rhoRatio = curve.slippage;
        int256 deltaA = domain.delta;
        int256 pA = midpointPrice;

        int256 k13 = LibFixedMath.two()
            .sub(rhoRatio)
            .mul(a)
            .mul(pA)
            .sub(rhoRatio.mul(b));

        int256 term1 = k13.square().add(
            LibFixedMath.four()
            .mul(pA)
            .mul(a)
            .mul(b)
        );

        int256 term2 = (-k13)
            .add(term1.sqrt())
            .div(
                LibFixedMath.two()
                .mul(pA)
            );

        int256 delta = LibFixedMath.min(deltaA, term2);
        return delta;
    }

    /// @dev Computes the expected future price of token `a` in terms of token `b`.
    ///      This function corresponds to Section 4.7 of the Whitepaper.
    function computeExpectedPrice(
        IStructs.BondingCurve memory curve,
        IStructs.PriceConstraints memory constraints,
        int256 midpointPrice,
        int256 deltaBlockNumber
    )
        internal
        pure
        returns (int256 expectedPrice)
    {
        // Define constants
        int256 k1 = constraints.persistence.pow(deltaBlockNumber);
        int256 k2 = LibFixedMath.one().sub(k1);

        // Define terms
        int256 term1 = midpointPrice.mul(k2);
        int256 term2 = curve.expectedPrice.mul(k1);
        int256 term3D = curve.expectedPrice.mul(k2).add(midpointPrice.mul(k1));
        int256 term3 = midpointPrice.mul(curve.expectedPrice).div(term3D);

        // Compute expected price
        expectedPrice = term1
            .add(term2)
            .add(term3)
            .div(LibFixedMath.two());

        // Handle constraints
        int256 minExpectedPrice = curve.expectedPrice.div(constraints.variability);
        int256 maxExpectedPrice = curve.expectedPrice.mul(constraints.variability);
        if(expectedPrice < minExpectedPrice) {
            expectedPrice = minExpectedPrice;
        } else if (expectedPrice > maxExpectedPrice) {
            expectedPrice = maxExpectedPrice;
        }

        return expectedPrice;
    }
}
