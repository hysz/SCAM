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

        // 1.005012520859401063383566241124068580734875538593956360758...

        gState.eToKappa = LibFixedMath.toFixed(int256(100050012502), int256(100000000000));
        gState.isInitialized = true;


        // Set token supplies
        gState.x = c.x;
        gState.y = c.y;

        // _initState(0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000001);



        // Run trades
        for (uint i = 0; i < trades.length; ++i) {
            blockNumber = trades[i].blockNumber;
            swap(trades[i].takerToken, trades[i].makerToken, trades[i].takerAmount);
        }
        blockNumber = 0;

        // Return final state
        return ContractState({
            x: gState.x,
            y: gState.y,
            pBarX: gState.pBarX,
            t: gState.t
        });
    }

    function testMul(int256 i, int256 j) public returns (int256) {
        return i.mul(j);
    }

    function testDiv(int256 i, int256 j) public returns (int256) {
        return i.div(j);
    }


    function testMantissa(int256 i) public returns (int256) {
        return i.toMantissa();
    }

    function _getCurrentBlockNumber()
        internal
        returns (uint256)
    {
        return blockNumber;
    }
}
