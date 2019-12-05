pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../interfaces/IStructs.sol";

import "../libs/LibFixedMath.sol";
import "../libs/LibSafeMath.sol";
import "../libs/LibScamMath.sol";
import "../core/State.sol";


contract Swapper is
    State
{

    using LibFixedMath for int256;

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
        int256 price = _bisect(
            a,
            b,
            pBarA,
            LibFixedMath.toFixed(amount),
            state
        );


    }

    function _bisect(
        int256 a,
        int256 b,
        int256 pBarA,
        int256 amount,
        IStructs.State memory state
    )
        internal
        returns (int256 r)
    {
        // Compute initial midpoint on bond curve; this will be the initial lower bound.
        int256 pA = LibScamMath.computeMidpointOnBondCurve(
            pBarA,
            b,
            state.rhoRatio
        );

        // Compute initial bounds.
        int256 lowerBound = 0;
        int256 upperBound = pA;

        // Cache this value for computations.
        int256 aPlusAmount = a.add(amount);

        //
        for (uint256 i = 0; i < state.bisectionIterations; ++i) {
            int256 mid = LibScamMath.computeMidpoint(lowerBound, upperBound);


            int256 lhs1 = LibScamMath.computeBaseToNinetyNine(mid.div(pBarA));
            int256 lhs = aPlusAmount
                .mul(lhs1)
                .mul(mid)
                .add(amount.mul(mid));
            if (lhs > b) {
                upperBound = mid;
            } else {
                lowerBound = mid;
            }
        }

        return lowerBound;
    }

    function _()
        internal
    {

    }

}
