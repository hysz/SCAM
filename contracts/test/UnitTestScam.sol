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
        //int256 baseFeeHigh;
        int256 beta;
        int256 kappa;
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
        Trade[] calldata trades,
        bool throwOnFailure
    )
        external
        returns (ContractState memory)
    {

        gState.assets = IStructs.AssetPair({
            xAsset: address(0x0000000000000000000000000000000000000000),
            yAsset: address(0x0000000000000000000000000000000000000001)
        });

        gState.curve = LibBondingCurve.createBondingCurve(
            c.x,
            c.y,
            c.pBarX,
            p.rho
        );


        // Init
        //gState.xAddress = ;
        //gState.yAddress = ;
        //gState.pBarX = c.pBarX;
        // UNUSED gState.rhoNumerator = 0;
        //gState.rhoRatio = p.rho;
        gState.fee = p.baseFee;    // 0.0005
        gState.feeHigh = p.baseFee + LibFixedMath.toFixed(int256(2), int256(1000)); /*p.extraFee*/
        gState.beta = p.beta;
        gState.t = 0;

        // 1.005012520859401063383566241124068580734875538593956360758...

        gState.eToKappa = LibFixedMath.one().div(LibFixedMath.exp(-p.kappa));
        gState.isInitialized = true;


        // Set token supplies
       // gState.x = c.x;
       // gState.y = c.y;

        // _initState(0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000001);



        // Run trades
        for (uint i = 0; i < trades.length; ++i) {
            blockNumber = trades[i].blockNumber;
            if (throwOnFailure) {
                swap(
                    trades[i].takerToken,
                    trades[i].makerToken,
                    trades[i].takerAmount
                );
            } else {
                bytes memory swapCalldata = abi.encodeWithSelector(
                Scam(address(0)).swap.selector,
                    trades[i].takerToken,
                    trades[i].makerToken,
                    trades[i].takerAmount
                );
                address(this).call(swapCalldata);
            }
        }
        blockNumber = 0;

        // Return final state
        return ContractState({
            x: gState.curve.xReserve,
            y: gState.curve.yReserve,
            pBarX: gState.curve.expectedFuturePrice,
            t: gState.t
        });
    }

    function testMul(int256 i, int256 j) public returns (int256) {
        return i.mul(j);
    }

    function testDiv(int256 i, int256 j) public returns (int256) {
        return i.div(j);
    }

    function testPow(int256 i, int256 j) public returns (int256) {
        return i.pow(j);
    }


    function testMantissa(int256 i) public returns (int256) {
        return i.toMantissa();
    }

    function getRanges() public returns (int256,int256,int256,int256) {
        return LibFixedMath.getRanges();
    }

    function _getCurrentBlockNumber()
        internal
        returns (uint256)
    {
        return blockNumber;
    }
}
