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
        int256 t;
    }

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
        BondCurveParams calldata p,
        ContractState calldata c,
        Trade[] calldata trades,
        bool throwOnFailure
    )
        external
        returns (ContractState memory)
    {

        gAMM.assets = IStructs.AssetPair({
            xAsset: address(0x0000000000000000000000000000000000000000),
            yAsset: address(0x0000000000000000000000000000000000000001),
            xDecimals: 18,
            yDecimals: 18
        });

        gAMM.curve = IStructs.BondingCurve({
            xReserve: 0,
            yReserve: 0,
            expectedPrice: 0,
            slippage: p.rho
        });

        gAMM.fee = IStructs.Fee({
            lo: p.baseFee,
            hi: p.baseFee + LibFixedMath.toFixed(int256(2), int256(1000))
        });

        gAMM.constraints = IStructs.PriceConstraints({
            persistence: p.beta,
            variability: LibFixedMath.one().div(LibFixedMath.exp(-p.kappa))
        });

        gAMM.blockNumber = 0;

        _addLiquidity(c.x, c.y);
        _gCurve.expectedPrice = c.pBarX;
        _gCurve.slippage = p.rho;

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
        blockNumber = 0;

        // Return final state
        return ContractState({
            x: _gCurve.xReserve,
            y: _gCurve.yReserve,
            pBarX: _gCurve.expectedPrice,
            t: _gBlockNumber
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
        view
        returns (int256)
    {
        return blockNumber;
    }
}