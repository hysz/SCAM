pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../interfaces/IStructs.sol";
import "../interfaces/IEvents.sol";
import "../libs/LibFixedMath.sol";
import "../libs/LibSafeMath.sol";
import "../libs/LibScamMath.sol";
import "../core/State.sol";


contract Swapper is
    IEvents,
    State
{

    using LibFixedMath for int256;

    event Price(int256 price, int256 deltaB, int256 newPBarX);

    function swap(
        address fromToken,
        address toToken,
        uint256 amount
    )
        //external
        public
    {
        IStructs.State memory state = _loadGlobalState();

        // Compute initial balances (fixed point).
        int256 deltaA = LibFixedMath.toFixed(amount);
        int256 a = 0;
        int256 b = 0;
        int256 pBarA = 0;
        bool fromIsX;
        if (fromToken == state.xAddress && toToken == state.yAddress) {
            a = state.x;
            b = state.y;
            pBarA = state.pBarX;
            fromIsX = true;
        } else if(fromToken == state.yAddress && toToken == state.xAddress) {
            a = state.y;
            b = state.x;
            pBarA = state.pBarXInverted;
        } else {
            revert("Invalid token addresses");
        }

        // Compute
        (int256 pA, int256 price) = _bisect(
            a,
            b,
            pBarA,
            deltaA,
            state
        );

        // Compute about of `tokenB`
        int256 deltaB = deltaA
        .mul(price)
        .mul(
            LibFixedMath.one().sub(state.fee)
        );
        deltaB = int256(0).sub(deltaB); // negate

        // Edge Cases
        if (deltaB > 0) {
            deltaB = 0;
        } /* else if (b.add(deltaB) <= 10^-10) { @todo add
            deltaB = 10^-10 - b;
        }
        */



        // @TODO: Handle additional edge cases


        // Update balances
        if (fromIsX) {
            int256 newPBarX = LibScamMath.computeNewPBarA(
                //state.t,
                //block.number,
                0,
                570,
                state.beta,
                pA,
                state.pBarX
            );

            emit Price(
                price,
                deltaB,
                newPBarX
            );

            state.x = a.add(deltaA);
            state.y = b.add(deltaB);
            /*
                delta_p_bar_x = (sell_token_id == 'X') * (p_bar_a_prime - p_bar_x) + ...
                (sell_token_id == 'Y') * (1/p_bar_a_prime - p_bar_x);
            */
            // gState.pBarX = ...
            // gState.pBarXIneverted = ...
        } else {
            state.x = b.add(deltaB);
            state.y = a.add(deltaA);
            // gState.pBarX = ...
            // gState.pBarXIneverted = ...
        }

        // Update state
        _saveGlobalState(state);

        // Make transfers
        //IERC20(fromToken).transferFrom(msg.sender, address(this), uint256(deltaA));
        //IERC20(toToken).transferFrom(address(this), msg.sender, uint256(deltaB));

        // Emit event
        emit IEvents.Fill(
            msg.sender,
            fromToken,
            toToken,
            uint256(deltaA),
            uint256(deltaB)
        );
    }

    event Bisect(
        int256 lhs1,
        int256 mid,
        int256 lhs
    );

    function _bisect(
        int256 a,
        int256 b,
        int256 pBarA,
        int256 deltaA,
        IStructs.State memory state
    )
        internal
        returns (int256 pA, int256 r)
    {
        // Compute initial midpoint on bond curve; this will be the initial lower bound.
        pA = LibScamMath.computeMidpointOnBondCurve(
            a,
            b,
            pBarA,
            state.rhoRatio
        );

        // Compute initial bounds.
        int256 lowerBound = 0;
        int256 upperBound = pA;

        // Cache this value for computations.
        int256 aPlusAmount = a.add(deltaA);

        //
        for (uint256 i = 0; i < /*state.bisectionIterations*/ 20; ++i) {
            int256 mid = LibScamMath.computeMidpoint(lowerBound, upperBound);
            int256 lhs1 = LibScamMath.computeBaseToNinetyNine(mid.div(pBarA));
            int256 lhs = aPlusAmount
                .mul(lhs1)
                .mul(mid)
                .add(deltaA.mul(mid));
            emit Bisect(
                lhs1,
                mid,
                lhs
            );
            if (lhs > b) {
                upperBound = mid;
            } else {
                lowerBound = mid;
            }
        }

        return (pA, lowerBound);
    }
}
