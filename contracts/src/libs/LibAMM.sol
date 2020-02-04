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
import "./LibPriceDiscovery.sol";


library LibAMM {

    using LibFixedMath for int256;
    using LibBondingCurve for IStructs.BondingCurve;

    // Fixed-point numbers used by this library
    int256 private constant ONE = int256(0x0000000000000000000000000000000080000000000000000000000000000000);

    // The minimum allowed balance of an asset after a trade.
    int256 private constant MIN_ALLOWED_BALANCE = int256(0x00000000000000000000000000000000000053e2d6238da3c21187e7c06e19b9);// 1/10^5

    // A dust amount taken off each sell to account for rounding errors.
    // This ensures that rounding always favors the AMM.
    int256 private constant AMM_EDGE = int256(0x00000000000000000000000000000000000008637bd05af6c69b5a63f9a49c2c); // 10^-6

    function trade(
        IStructs.AMM memory amm,
        address takerAsset,
        int256 takerAssetAmount,
        int256 currentBlockNumber
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

        // Compute initial midpoint price on bond curve; this is the upper-bound on maker price.
        int256 maxMakerPrice = curve.computeMidpointPrice();

        // Compute the maximum price on the bond curve; this is the lower-bound on maker price.
        int256 minMakerPrice = curve.computeMinPriceInDomain(
            IStructs.Domain({x: curve.xReserve, delta: takerAssetAmount}),
            maxMakerPrice
        );

        // Compute best price. This is in the range [maxMakerPrice..minMakerPrice].
        int256 bestMakerPrice = LibPriceDiscovery.computeBestPrice(
            curve,
            maxMakerPrice,
            minMakerPrice,
            takerAssetAmount,
            fee
        );

        // Compute the `makerAssetAmount` from the Best Price.
        int256 makerAssetAmount = computeMakerAssetAmount(
            curve,
            bestMakerPrice,
            takerAssetAmount,
            fee
        );

        // Update curve with new token reserves and expected price.
        curve.xReserve = curve.xReserve.add(takerAssetAmount);
        curve.yReserve = curve.yReserve.sub(makerAssetAmount);
        curve.expectedPrice = curve.computeExpectedPrice(
            amm.constraints,
            maxMakerPrice,
            currentBlockNumber.sub(amm.blockNumber)
        );

        // Update AMM with new curve and block number.
        amm.curve = LibBondingCurve.transformTradeBondingCurveForStorage(
            curve,
            amm.assets,
            takerAsset
        );
        amm.blockNumber = currentBlockNumber;
    }

    function computeMakerAssetAmount(
        IStructs.BondingCurve memory curve,
        int256 price,
        int256 takerAssetAmount,
        int256 fee
    )
        internal
        pure
        returns (int256 makerAssetAmount)
    {
        // Compute maker asset amount, given taker asset amount, price and fee.
        makerAssetAmount = takerAssetAmount
            .mul(price)
            .mul(ONE.sub(fee));

        // Subtract a dust amount to ensure the trade favors the contract.
        makerAssetAmount = makerAssetAmount.sub(AMM_EDGE);

        // Sanity check that maker asset amount is positive.
        if (makerAssetAmount <= 0) {
            revert("Invalid Price. Cannot have a negative `makerAssetAmount`");
        }

        // Check that the remaining maker asset balance is valid.
        if (curve.yReserve.sub(makerAssetAmount) < MIN_ALLOWED_BALANCE) {
            revert("Invalid `takerAssetAmount`. Insufficient funds.");
        }

        return makerAssetAmount;
    }
}
