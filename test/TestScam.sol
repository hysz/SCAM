pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../contracts/interfaces/IStructs.sol";
import "../contracts/Scam.sol";
import "../contracts/libs/LibFixedMath.sol";


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
        gState.x = uint256(100000).toFixed();           // initial balance of Token X
        gState.y = uint256(100000).toFixed();           // initial balance of Token Y
        gState.pBarX = uint256(1).toFixed();            // initial expected price of X given Y
        gState.rhoNumerator = uint256(99);
        gState.rhoRatio = LibFixedMath.toFixed(int256(99), int256(100));
        gState.fee = LibFixedMath.toFixed(int256(5), int256(10000));    // 0.0005

        swap(gState.xAddress, gState.yAddress, 500);
    }
}
