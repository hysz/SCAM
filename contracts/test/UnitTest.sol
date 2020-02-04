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

    int256 blockNumber;
    IStructs.AMM gAMM;

    struct Trade {
        address makerToken;
        address takerToken;
        uint256 takerAmount;
        uint256 blockNumber;
    }

     function _getDefaultAMM()
        internal
        view
        returns (IStructs.AMM memory)
    {
        return gAMM;
    }

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

    function _getCurrentBlockNumber()
        internal
        view
        returns (int256)
    {
        return blockNumber;
    }
}
