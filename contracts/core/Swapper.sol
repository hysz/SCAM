pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../interfaces/IStructs.sol";

import "../libs/LibFixedMath.sol";
import "../libs/LibSafeMath.sol";
import "../core/State.sol";


contract Swapper is
    State
{

    using LibSafeMath for uint256;

    function swap(
        address fromAddress,
        address toAddress,
        uint256 amount
    )
        external
    {
        IStructs.State memory state = gState;

        // Compute initial balances (fixed point).
        int256 a = 0;
        int256 b = 0;
        int256 pBarA = 0;
        if (fromAddress == state.xAddress && toAddress == state.yAddress) {
            a = state.x;
            b = state.y;
            pBarA = state.pBarX;
        } else if(fromAddress == state.yAddress && toAddress == state.xAddress) {
            a = state.y;
            b = state.x;
            pBarA = state.pBarXInverted;
        } else {
            revert("Invalid token addresses");
        }

        // Compute
    }

    function _bisect(
        int256 a,
        int256 b,
        int256 pBarA,
        IStructs.State memory state
    )
        internal
        returns (int256 r)
    {


    }

    function _()
        internal
    {

    }

}
