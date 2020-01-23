pragma solidity 0.5.9;
pragma experimental ABIEncoderV2;

import "../interfaces/IStructs.sol";
import "../Scam.sol";
import "../libs/LibFixedMath.sol";


contract UnitTestScam is
    Scam
{

    using LibFixedMath for uint256;
    using LibFixedMath for int256;

    uint256 blockNumber;


    struct BondCurveParams {
        int256 rho;
        int256 baseFee;
        int256 beta;
    }

    struct ContractState {
        int256 x;
        int256 y;
        int256 pBarX;
        uint256 t;
    }

    struct Trade {
        address makerToken;
        address takerToken;
        uint256 takerAmount;
        uint256 blockNumber;
    }

    function greg()
    external
    {

    }



    function runUnitTest(
        BondCurveParams calldata p,
        ContractState calldata c,
        Trade[] calldata trades
    )
        external
        returns (ContractState memory)
    {

        // Init
        gState.xAddress = address(0x0000000000000000000000000000000000000000);
        gState.yAddress = address(0x0000000000000000000000000000000000000001);
        gState.pBarX = c.pBarX;
        // UNUSED gState.rhoNumerator = 0;
        gState.rhoRatio = p.rho;
        gState.fee = p.baseFee;    // 0.0005
        gState.beta = p.beta;
        gState.eToKappa = LibFixedMath.toFixed(int256(10005), int256(1000));
        gState.isInitialized = true;


        // Set token supplies
        gState.x = c.x;
        gState.y = c.y;

        // _initState(0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000001);



        // Run trades
        for (uint i = 0; i < trades.length; ++i) {
            //blockNumber = trades[i].blockNumber;
            swap(trades[i].takerToken, trades[i].makerToken, trades[i].takerAmount);
           // revert('made it to first');
        }
        blockNumber = 0;



        // Return final state
        return ContractState({
            x: gState.x,
            y: gState.y,
            pBarX: uint256(500).toFixed(),
            t: 0
        });
    }

    function _getCurrentBlockNumber()
        internal
        returns (uint256)
    {
        return blockNumber;
    }
}
