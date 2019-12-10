pragma solidity 0.5.9;
pragma experimental ABIEncoderV2;

import "../interfaces/IStructs.sol";
import "../Scam.sol";
import "../libs/LibFixedMath.sol";


contract TestScam is
    Scam
{

    using LibFixedMath for uint256;
    using LibFixedMath for int256;

    //uint256 block;

    function init()
        external
    {
         _initState(0x0000000000000000000000000000000000000001, 0x0000000000000000000000000000000000000002);

        // set initial blaances
        gState.x = uint256(500).toFixed();           // initial balance of Token X
        gState.y = uint256(1000).toFixed();            // initial balance of Token Y
    }

     function runBasicTest()
        external
    {
        //block = 570;
        swap(
            gState.xAddress,
            gState.yAddress,
            75 * 10**18
        );

/*
        block = 1570;
        swap(
            gState.xAddress,
            gState.yAddress,
            400 * 10**18
        );

        block = 4000;
        swap(
            gState.yAddress,
            gState.xAddress,
            220 * 10**6
        );
        */
    }

    function _getCurrentBlockNumber()
        internal
        returns (uint256)
    {
        return block.number; // block
    }
}
