pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../interfaces/IStructs.sol";
import "../Scam.sol";
import "../libs/LibFixedMath.sol";


contract TestScam is
    Scam
{

    using LibFixedMath for uint256;
    using LibFixedMath for int256;

    function runBasicTest()
        external
    {
        // For us
        gState.xAddress = 0x0000000000000000000000000000000000000001;
        gState.yAddress = 0x0000000000000000000000000000000000000002;

        // From Peter
        gState.y = uint256(100000).toFixed();           // initial balance of Token X
        gState.x = uint256(50000).toFixed();            // initial balance of Token Y
        gState.pBarX = uint256(1).toFixed();            // initial expected price of X given Y
        gState.rhoNumerator = uint256(99);
        gState.rhoRatio = LibFixedMath.toFixed(uint256(99), uint256(100));
        gState.fee = LibFixedMath.toFixed(uint256(5), uint256(10000));    // 0.0005

        gState.beta = LibFixedMath.one().sub(
            LibFixedMath.toFixed(int256(1), int256(1000000))
        );
        gState.eToKappa = LibFixedMath.toFixed(int256(10005), int256(1000));

        /*
        swap(
            gState.xAddress,
            gState.yAddress,
            10000
        );
        */

        swap(
            gState.yAddress,
            gState.xAddress,
            10000
        );
    }

    function _getCurrentBlockNumber()
        internal
        returns (uint256)
    {
        return 570;
    }
}
