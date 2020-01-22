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

    event Price2(int256 price);

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

        // Compute initial midpoint on bond curve; this will be the initial lower bound.
        int256 pA = LibScamMath.computeMidpointOnBondCurve(
            a,
            b,
            pBarA,
            state.rhoRatio
        );

        // Compute

        int256 price = _bracket(
            a,
            b,
            pA,
            pBarA,
            deltaA,
            state
        );



        /*
        (int256 price) = _bisect(
            a,
            b,
            pA,
            pBarA,
            deltaA,
            state
        );
        */
        emit Price2(price);

        return 0;

/*

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
        */
    }

    event Bisect(
        int256 lhs1,
        int256 mid,
        int256 lhs
    );

    event T(
        int256 a,
        int256 b,
        int256 pA,
        int256 pBarA,
        int256 deltaA,
        int256 rhoRatio,
        int256 term4,
        int256 k13
    );

    function _computeStep0(
        int256 a,
        int256 b,
        int256 pA,
        int256 pBarA,
        int256 deltaA,
        IStructs.State memory state
    )
        internal
        returns (int256)
    {
        int256 two = LibFixedMath.toFixed(int256(2));
        int256 k13 = two.sub(state.rhoRatio).mul(a).mul(pA).sub(state.rhoRatio.mul(b));

        int256 term1 = k13.square().add(
            LibFixedMath.toFixed(int256(4))
            .mul(pA)
            .mul(a)
            .mul(b)
        );
        int256 term2 = -(LibFixedMath.one()
            .div(term1)
            .ln()
            .div(two));


        int256 term3 = (term2 <= 0)
            ? term2.exp()
            : LibFixedMath.one().div(
                (-term2).exp()
            );

        int256 term4 = (-k13)
            .add(term3)
            .div(two.mul(pA));

        int256 delta = LibFixedMath.min(deltaA, term4);
        return delta;
    }

    function _computeStep1(
        int256 a,
        int256 b,
        int256 pA,
        int256 pBarA,
        int256 deltaA,
        int256 delta,
        IStructs.State memory state
    )
        internal
        returns (int256)
    {
        int256 term1 = a.mul(b.sub(delta.mul(pA)));
        int256 term2 = b.mul(a.add(delta));
        int256 term3 = term1.div(term2).ln();
        int256 term4 = LibFixedMath.one().sub(state.rhoRatio).mul(term3);
        int256 term5 = term4.exp().mul(delta).div(deltaA);
        return term5;
    }

    event E(
        int256 term2,
        int256 term3
    );

    function _computeStep2(
        int256 a,
        int256 b,
        int256 pA,
        int256 pBarA,
        int256 deltaA,
        int256 k8,
        int256 k12,
        IStructs.State memory state
    )
        internal
        returns (int256)
    {
        int256 term1 = k12.div(k8);
        int256 term2 = state.rhoRatio.add(
            LibFixedMath.one()
            .sub(state.rhoRatio)
            .mul(k12)
        );
        int256 term3 = LibFixedMath.one().add(
            LibFixedMath.one()
            .sub(state.rhoRatio)
            .mul(k8)
        );
        int256 term4 = term2.div(term3);
        return term1 < term4
            ? term1
            : term4;
    }

    function _computeStep3(
        int256 rl,
        int256 rh,
        int256 k8,
        int256 k12,
        IStructs.State memory state
    )
        internal
        returns (int256 newRh, int256 yl)
    {
        yl = LibScamMath.computeBaseToOneHundred(rl);
        int256 term1 = state.rhoRatio.mul(yl)
            .add(
                LibFixedMath.one()
                .sub(state.rhoRatio)
                .mul(k12)
            );
        int256 term2 = yl
            .add(
                LibFixedMath.one()
                .sub(state.rhoRatio)
                .mul(k8)
                .mul(rl)
            );
        int term3 = rl.mul(term1).div(term2);

        newRh = term3 < rh
            ? term3
            : rh;

        return (newRh, yl);
    }

    event EGGG(
        int256 rl,
        int256 rh,
        int256 yl,
        int256 yh
    );

    function _computeA(int256 rl, int256 rh)
        internal
        returns (int256)
    {
        return rl.mul(LibFixedMath.toFixed(int256(4)))
            .add(rh.mul(LibFixedMath.toFixed(int256(6))))
            .div(LibFixedMath.toFixed(int256(10)));
    }

     function _computeStep4(
        int256 rl,
        int256 rh,
        int256 k8,
        int256 k12,
        int256 yl,
        IStructs.State memory state
    )
        internal
        returns (
            int256 newRl,
            int256 newRh,
            int256 newYl,
            int256 newYh
        )
    {
        // compute yBis
        int256 term1 = _computeA(rl, rh);
        int256 yBis = LibScamMath.computeBaseToOneHundred(term1);

        //
        int256 term2 = k12.sub(k8.mul(term1));
        if (yBis <= term2) {
            return (
                term1,
                rh,
                yBis,
                LibScamMath.computeBaseToOneHundred(rh)
            );
        } else {
            return (
                rl,
                term1,
                yl,
                yBis
            );
       }
    }

    function _computeStep5(
        int256 rl,
        int256 rh,
        int256 yl,
        int256 yh,
        int256 k8,
        int256 k12
    )
        internal
        returns (int256)
    {
        int256 term1 = yh.mul(rl)
            .sub(yl.mul(rh))
            .add(k12.mul(rh.sub(rl)));
        int256 term2 = yh
            .sub(yl)
            .add(k8.mul(rh.sub(rl)));
        int256 term3 = term1.div(term2);

        return term3 > rl
            ? term3
            : rl;
    }

    function _computeStep6(
        int256 rl
    )
        internal
        returns (int256)
    {
        return rl < LibFixedMath.toFixed(int256(9), int256(10))
            ? 0
            : rl;
    }

    function _shouldImprovePrecision(
        int256 rl,
        int256 rh,
        int256 fee
    )
        internal
        returns (bool shouldImprovePrecision)
    {
        int256 lhs = rh.sub(rl);
        int256 tao = LibFixedMath.toFixed(int256(1), int256(10));
        int256 rhs = tao.mul(
            fee.add(
                LibFixedMath.one().sub(rh)
            )
        );

        emit L(lhs,rhs);

        return lhs > rhs;
    }

    event L(
        int256 lhs,
        int256 rhs
    );

    function _bracket(
        int256 a,
        int256 b,
        int256 pA,
        int256 pBarA,
        int256 deltaA,
        IStructs.State memory state
    )
        internal
        returns (int256)
    {
        // Cache constants that are used throughout bracketing algorithm.
        int256 k8 = a.mul(
            pA
            .mul(deltaA)
            .div(a.mul(b).add(b.mul(deltaA)))
        );
        int256 k12 = a.div(
            a.add(deltaA)
        );

        //////// Run bracketing ///////
        int256 delta = _computeStep0(
            a,
            b,
            pA,
            pBarA,
            deltaA,
            state
        );

        int256 rl = _computeStep1(
            a,
            b,
            pA,
            pBarA,
            deltaA,
            delta,
            state
        );

/*
        int256 rh = _computeStep2(
            a,
            b,
            pA,
            pBarA,
            deltaA,
            k8,
            k12,
            state
        );


        if (_shouldImprovePrecision(rl, rh, state.fee)) {
            int256 yl;
            (rh, yl) = _computeStep3(
                rl,
                rh,
                k8,
                k12,
                state
            );

            if (_shouldImprovePrecision(rl, rh, state.fee)) {
                int256 yh;
                (rl, rh, yl, yh) = _computeStep4(
                    rl,
                    rh,
                    k8,
                    k12,
                    yl,
                    state
                );

                if (_shouldImprovePrecision(rl, rh, state.fee)) {
                    rl = _computeStep5(
                        rl,
                        rh,
                        yl,
                        yh,
                        k8,
                        k12
                    );
                }
            }
        }
        */

        // Step 6
        rl = _computeStep6(rl);

        // Step 7
        return rl.mul(pA);
    }

    function _bisect(
        int256 a,
        int256 b,
        int256 pA,
        int256 pBarA,
        int256 deltaA,
        IStructs.State memory state
    )
        internal
        returns (int256 r)
    {
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
            if (lhs > b) {
                upperBound = mid;
            } else {
                lowerBound = mid;
            }
        }

        return lowerBound;
    }

    function _getCurrentBlockNumber()
        internal
        returns (uint256)
    {
        return block.number;
    }
}
