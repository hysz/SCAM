pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../interfaces/IStructs.sol";
import "../interfaces/IEvents.sol";
import "../libs/LibFixedMath.sol";
import "../libs/LibSafeMath.sol";
import "../libs/LibScamMath.sol";
import "../libs/LibToken.sol";
import "../core/State.sol";
import "../interfaces/IERC20.sol";


contract Swapper is
    IEvents,
    State
{

    using LibFixedMath for int256;

    event Price(int256 price, int256 deltaB, int256 newPBarX, int256 pA);

    function swap(
        address fromToken,
        address toToken,
        uint256 amount
    )
        public
        returns (uint256 amountReceived)
    {
        IStructs.State memory state = _loadGlobalState();

        if (fromToken == state.xAddress && toToken == state.yAddress) {
            int256 amountReceivedFixed = _swap(
                fromToken,
                toToken,
                LibToken.daiToFixed(amount),
                state
            );
            amountReceived = LibToken.usdcFromFixed(amountReceivedFixed);
        } else if(fromToken == state.yAddress && toToken == state.xAddress) {
            int256 amountReceivedFixed = _swap(
                fromToken,
                toToken,
                LibToken.usdcToFixed(amount),
                state
            );
            amountReceived = LibToken.daiFromFixed(amountReceivedFixed);
        } else {
            revert("Invalid token addresses");
        }

        // Make transfers
        /*
        require(
            IERC20(fromToken).transferFrom(msg.sender, address(this), amount),
            'INSUFFICIENT_FROM_TOKEN_BALANCE'
        );
        require(
            // IERC20(toToken).transferFrom(address(this), msg.sender, amountReceived),
            IERC20(toToken).transfer(msg.sender, amountReceived),
            'INSUFFICIENT_TO_TOKEN_BALANCE'
        );
        */

        // Emit event
        emit IEvents.Fill(
            msg.sender,
            fromToken,
            toToken,
            amount,
            amountReceived
        );

        return amountReceived;
    }

    function _swap(
        address fromToken,
        address toToken,
        int256 deltaA,
        IStructs.State memory state
    )
        internal
        returns (int256 amountReceived)
    {
        // Compute initial balances (fixed point).
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
            pBarA = LibFixedMath.one().div(state.pBarX);
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
        int256 epsilon = LibFixedMath.toFixed(int256(1), int256(100000)); // Good for USDC, may vary w token.
        if (deltaB > 0) {
            deltaB = 0;
        } else if (b.add(deltaB) <= epsilon) {
            deltaB = epsilon.sub(b);
        }

        // Handle additional edge cases
        int256 newPBarA = LibScamMath.computeNewPBarA(
            state.t,
            _getCurrentBlockNumber(),
            state.beta,
            pA,
            pBarA
        );
        if (newPBarA > state.eToKappa.mul(pBarA)) {
            newPBarA = state.eToKappa.mul(pBarA);
        } else if(newPBarA < LibFixedMath.one().div(state.eToKappa).mul(pBarA)) {
            newPBarA = LibFixedMath.one().div(state.eToKappa).mul(pBarA);
        }

        // Update state
        state.t = _getCurrentBlockNumber();
        if (fromIsX) {
            state.x = a.add(deltaA);
            state.y = b.add(deltaB);
            state.pBarX = newPBarA;
        } else {
            state.x = b.add(deltaB);
            state.y = a.add(deltaA);
            state.pBarX = LibFixedMath.one().div(newPBarA);
        }

        // Update state
        _saveGlobalState(state);

        emit IEvents.FillInternal(
                msg.sender,
                deltaA,
                deltaB
        );

        amountReceived = -deltaB;
        return amountReceived;
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
        for (uint256 i = 0; i < 20; ++i) {
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

    function _getCurrentBlockNumber()
        internal
        returns (uint256)
    {
        return block.number;
    }
}
