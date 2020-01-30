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

    function computePrice()
        internal
        pure
    {
        /*
        int256 lowerBound = LibBondingCurve.computeMaximumPriceInDomain();
        int256 upperBound =
        */
    }

    function trade(
        IStructs.AMM memory amm,
        address takerAsset,
        int256 deltaA,
        uint256 currentBlockNumber
    )
        internal
        returns (
            int256 amountReceived
        )
    {
        int256 fee = (amm.blockNumber != currentBlockNumber)
            ? amm.fee.lo
            : amm.fee.hi;

        // Transform stored curve for this trade.
        IStructs.BondingCurve memory curve = LibBondingCurve.transformStoredBondingCurveForTrade(
            amm.curve,
            amm.assets,
            takerAsset
        );

        emit CURVE(curve);



        // Compute initial midpoint on bond curve; this will be the initial lower bound.
        int256 pA = curve.computeMidpointPrice();
        int256 rl = curve.computeMaximumPriceInDomain(
            IStructs.Domain({x: curve.xReserve, delta: deltaA}),
            pA
        );

        // Compute
        int256 price = LibRootFinding.bracket(
            curve,
            pA,
            deltaA,
            rl,
            fee
        );

         // Step 6
        _computeStep6(price);


        // Step 7
        price = price.mul(pA);

        emit VALUE("final price", price);


        if (price < 0)  {
            revert('price cannot be < 0');
        } else if (price == 0) {
            revert('price cannot be zero');
        }

        // Compute about of `tokenB`


        int256 deltaB = deltaA
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

        // Update curve
        curve.xReserve = curve.xReserve.add(deltaA);
        curve.yReserve = curve.yReserve.add(deltaB);
        curve.expectedFuturePrice = curve.computeExpectedPrice(
            amm.constraints,
            pA,
            LibFixedMath.toFixed(int256(currentBlockNumber - amm.blockNumber))
        );

        // Update state
        IStructs.AssetPair memory assets = amm.assets;
        amm.curve = LibBondingCurve.transformStoredBondingCurveForTrade(
            curve,
            assets,
            takerAsset
        );
        amm.blockNumber = currentBlockNumber;

        amountReceived = -deltaB;
    }

    function _computeStep6(
        int256 rl
    )
        internal
        pure
    {
        if (rl < LibFixedMath.toFixed(int256(95), int256(100))) {
            revert('Order too large');
        }
    }

    function isValidTrade()
        internal
        pure
        returns (bool)
    {
        /*
        int256 lowerBound = LibBondingCurve.computeMaximumPriceInDomain();
        int256 upperBound =

        */
    }



}