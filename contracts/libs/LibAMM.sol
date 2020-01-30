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
pragma experimental ABIEncoderV2;

import "../interfaces/IEvents.sol";
import "../interfaces/IStructs.sol";
import "./LibFixedMath.sol";
import "./LibBondingCurve.sol";
import "./LibRootFinding.sol";


library LibAMM {

    using LibFixedMath for int256;
    using LibBondingCurve for IStructs.BondingCurve;

    event VALUE(
        string description,
        int256 val
    );

    event CURVE(
        IStructs.BondingCurve curve
    );

    function trade(
        IStructs.AMM memory amm,
        address takerAsset,
        int256 takerAssetAmount,
        uint256 currentBlockNumber
    )
        internal
        returns (
            int256 amountReceived
        )
    {
        // Compute fee. If a trade has already occurred in this block
        // then we charge a higher fee. This also creates more competition among arbitrageurs,
        // as they will race to get the lower fee. Moreover, it also mitigates:
        //   1. Circumventing the batch-auction model by splitting a large trade into several small trades.
        //   2. Front-running arbitrage attacks (front-run large fill; large fill moves price; sell at profit)
        int256 fee = (amm.blockNumber != currentBlockNumber)
            ? amm.fee.lo
            : amm.fee.hi;

        // Transform stored curve for this trade.
        IStructs.BondingCurve memory curve = LibBondingCurve.transformStoredBondingCurveForTrade(
            amm.curve,
            amm.assets,
            takerAsset
        );

        // Compute initial midpoint on bond curve; this is the initial upper-bound
        // and would result in the greatest makerAssetAmount.
        int256 minPrice = curve.computeMidpointPrice();

        // Compute the maximum price on the bond curve; this is the initial lower-bound
        // and would result in the lowest makerAssetAmount.
        int256 maxPrice = curve.computeMaximumPriceInDomain(
            IStructs.Domain({x: curve.xReserve, delta: takerAssetAmount}),
            minPrice
        );

        // Compute best price. This lies in the range [minPrice..maxPrice].
        int256 bestPrice = computeBestPrice(
            curve,
            minPrice,
            maxPrice,
            takerAssetAmount,
            fee
        );

        int256 makerAssetAmount = computeMakerAssetAmount(
            curve,
            bestPrice,
            takerAssetAmount,
            fee
        );

        // Update curve
        curve.xReserve = curve.xReserve.add(takerAssetAmount);
        curve.yReserve = curve.yReserve.sub(makerAssetAmount);
        curve.expectedPrice = curve.computeExpectedPrice(
            amm.constraints,
            minPrice,
            LibFixedMath.toFixed(int256(currentBlockNumber - amm.blockNumber))
        );

        // Update AMM
        IStructs.AssetPair memory assets = amm.assets;
        amm.curve = LibBondingCurve.transformStoredBondingCurveForTrade(
            curve,
            assets,
            takerAsset
        );
        amm.blockNumber = currentBlockNumber;
    }

    function computeBestPrice(
        IStructs.BondingCurve memory curve,
        int256 minPrice,
        int256 maxPrice,
        int256 takerAssetAmount,
        int256 fee
    )
        private
        // pure
        returns (int256 bestPrice)
    {
        int256 root = LibRootFinding.bracket(
            curve,
            minPrice,
            takerAssetAmount,
            maxPrice,
            fee
        );

        // Step 6
        if (root < LibFixedMath.toFixed(int256(95), int256(100))) {
            revert('Order too large');
        }

        // Step 7
        bestPrice = root.mul(minPrice);

        emit VALUE("final price", bestPrice);


        if (bestPrice < 0)  {
            revert('price cannot be < 0');
        } else if (bestPrice == 0) {
            revert('price cannot be zero');
        }

        return bestPrice;
    }

    function computeMakerAssetAmount(
        IStructs.BondingCurve memory curve,
        int256 price,
        int256 takerAssetAmount,
        int256 fee
    )
        private
        // pure
        returns (int256 deltaB)
    {
         deltaB = takerAssetAmount
            .mul(price)
            .mul(
                LibFixedMath.one().sub(fee)
            );
        deltaB = -deltaB;

        if (deltaB >= 0) {
            revert('deltaB is greater or equal to zero');
        }

        // Edge Cases
        int256 epsilon = LibFixedMath.toFixed(int256(1), int256(100000));
        if (curve.yReserve.add(deltaB) <= epsilon) {
            deltaB = epsilon.sub(curve.yReserve);
            deltaB = (deltaB < 0) ? deltaB : 0;
        }

        // Round up to favor the contract
        // We impose a dust amount of 1/10^6. This is the minimum token amount.
        deltaB += LibFixedMath.toFixed(int256(1), int256(10**6));
        if (deltaB >= 0) {
            revert('Tried to purchase too much');
        }

        return -deltaB;
    }


}
