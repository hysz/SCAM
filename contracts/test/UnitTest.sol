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

pragma solidity 0.5.9;
pragma experimental ABIEncoderV2;

import "../src/interfaces/IStructs.sol";
import "../src/amm/AbstractAMM.sol";
import "../src/libs/LibFixedMath.sol";


contract UnitTest is
    AbstractAMM
{

    using LibFixedMath for uint256;
    using LibFixedMath for int256;

    int256 private blockNumber;
    IStructs.AMM private gAMM;

    struct Trade {
        address makerToken;
        address takerToken;
        uint256 takerAmount;
        uint256 blockNumber;
    }

    /// @dev Runs a unit test.
    function runUnitTest(
        IStructs.AMM memory amm,
        Trade[] memory trades,
        bool throwOnFailure
    )
        public
        returns (IStructs.AMM memory)
    {
        // Initialize state
        gAMM = amm;
        blockNumber = 0;

        // As an optimization our contracts store variability as exp(variability)
        gAMM.constraints.variability = LibFixedMath.one().div(LibFixedMath.exp(-gAMM.constraints.variability));

        // Store the initial curve (simulates depositing funds by updating the reserves).
        _gCurve = amm.curve;

        // Run trades
        for (uint i = 0; i < trades.length; ++i) {
            blockNumber = LibFixedMath.toFixed(int256(trades[i].blockNumber));
            if (throwOnFailure) {
                trade(
                    trades[i].takerToken,
                    trades[i].takerAmount
                );
            } else {
                bytes memory swapCalldata = abi.encodeWithSelector(
                AbstractAMM(address(0)).trade.selector,
                    trades[i].takerToken,
                    trades[i].takerAmount
                );
                address(this).call(swapCalldata);
            }
        }

        // Return final AMM
        return _getAMM();
    }

    /// @dev Returns the default AMM for the current unit test.
    function _getDefaultAMM()
        internal
        view
        returns (IStructs.AMM memory)
    {
        return gAMM;
    }

    // @dev Overrides `_getCurrentBlockNumber` in AbstractAMM.sol.
    function _getCurrentBlockNumber()
        internal
        view
        returns (int256)
    {
        return blockNumber;
    }
}
