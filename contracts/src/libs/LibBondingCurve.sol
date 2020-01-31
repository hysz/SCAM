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

    // 1 in fixed-point
    int256 private constant ONE = int256(0x0000000000000000000000000000000080000000000000000000000000000000);
    // 2 in fixed-point
    int256 private constant TWO = int256(0x0000000000000000000000000000000100000000000000000000000000000000);
    // 4 in fixed-point
    int256 private constant FOUR = int256(0x0000000000000000000000000000000200000000000000000000000000000000);

    function createBondingCurve(
        int256 xReserve,
        int256 yReserve,
        int256 expectedPrice,
        int256 slippage
    )
        internal
        pure
        returns (IStructs.BondingCurve memory)
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
    ///        of the c, depending on which assets is being traded.
    ///        The inputs to this function are not mutated during execution.
    function transformStoredBondingCurveForTrade(
        IStructs.BondingCurve memory c,
        IStructs.AssetPair memory assets,
        address takerAsset
    )
        internal
        pure
        returns (IStructs.BondingCurve memory)
    {
        // We store the bonding curve with the X-Asset on the X-Axis.
        // If the Taker Asset is the Y-Asset then we invert the c
        // for computations (and then invert it again before storing the updated c).
        if (takerAsset == assets.xAsset) {
            return createBondingCurve(
                c.xReserve,
                c.yReserve,
                c.expectedPrice,
                c.slippage
            );
        } else {
            return createBondingCurve(
                c.yReserve,
                c.xReserve,
                ONE.div(c.expectedPrice),
                c.slippage
            );
        }
    }

    function transformTradeBondingCurveForStorage(
        IStructs.BondingCurve memory c,
        IStructs.AssetPair memory assets,
        address takerAsset
    )
        internal
        pure
        returns (IStructs.BondingCurve memory)
    {
        return transformStoredBondingCurveForTrade(c, assets, takerAsset);
    }

    /// @dev This returns the price at a specific point (a,b) on the token bond c,
    ///      which is defined by the slope of the tangent at (a,b).
    function computeMidpointPrice(IStructs.BondingCurve memory c)
        internal
        pure
        returns (int256 price)
    {
        // Define terms
        int256 t1 = c.yReserve.div(c.expectedPrice.mul(c.xReserve));
        int256 t2 = t1.pow(ONE.sub(c.slippage));

        // Compute price
        price = c.expectedPrice.mul(t2);
    }

    /// @dev Computes the highest price to sell token `b` in the range [a, a + deltaA].
    ///
    ///      Implementation Note: Difference in this PRICE computation.
    function computeMaximumPriceInDomain(
        IStructs.BondingCurve memory c,
        IStructs.Domain memory domain,
        int256 midpointPrice
    )
        internal
        pure
        returns (int256 price)
    {
        // Compute offset to x-coordinate with maximum price
        int256 delta = computeOffsetToMaximumPriceInDomain(c, domain, midpointPrice);

        // Define terms
        int256 t1 = c.xReserve.mul(c.yReserve.sub(delta.mul(midpointPrice)));
        int256 t2 = c.yReserve.mul(c.xReserve.add(delta));
        int256 t3 = t1.div(t2);
        int256 t4 = t3.pow(ONE.sub(c.slippage));
        int256 t5 = t4.mul(delta).div(domain.delta);

        // Compute price
        price = t5.mul(midpointPrice);
    }

    /// @dev Computes the offset to the highest price to sell token `b` in the range [a, a + deltaA].
    ///      To do this we find the nearest local maxima, which is defined as
    ///      the point where the first derivative is zero and the second derivative
    ///      is decreasing. If this point is greater than the domain limit of `a + deltaA`,
    ///      then the maximum price is at `a + deltaA`.
    function computeOffsetToMaximumPriceInDomain(
        IStructs.BondingCurve memory c,
        IStructs.Domain memory domain,
        int256 midpointPrice
    )
        internal
        pure
        returns (int256 delta)
    {
        // Define constants
        int256 k1 = TWO
            .sub(c.slippage)
            .mul(c.xReserve)
            .mul(midpointPrice)
            .sub(c.slippage.mul(c.yReserve));

        // Define terms
        int256 t1 = k1.square().add(
            FOUR
            .mul(midpointPrice)
            .mul(c.xReserve)
            .mul(c.yReserve)
        );
        int256 t2 = (-k1)
            .add(t1.sqrt())
            .div(TWO.mul(midpointPrice));

        // Compute delta
        delta = LibFixedMath.min(domain.delta, t2);
    }

    /// @dev Computes the expected future price of token `a` in ts of token `b`.
    ///      This function corresponds to Section 4.7 of the Whitepaper.
    function computeExpectedPrice(
        IStructs.BondingCurve memory c,
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
        int256 k2 = ONE.sub(k1);

        // Define terms
        int256 t1 = midpointPrice.mul(k2);
        int256 t2 = c.expectedPrice.mul(k1);
        int256 t3D = c.expectedPrice.mul(k2).add(midpointPrice.mul(k1));
        int256 t3 = midpointPrice.mul(c.expectedPrice).div(t3D);

        // Compute expected price
        expectedPrice = t1
            .add(t2)
            .add(t3)
            .div(TWO);

        // Handle constraints
        int256 minExpectedPrice = c.expectedPrice.div(constraints.variability);
        int256 maxExpectedPrice = c.expectedPrice.mul(constraints.variability);
        if(expectedPrice < minExpectedPrice) {
            expectedPrice = minExpectedPrice;
        } else if (expectedPrice > maxExpectedPrice) {
            expectedPrice = maxExpectedPrice;
        }
    }
}
