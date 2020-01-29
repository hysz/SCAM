pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../interfaces/IStructs.sol";
import "../interfaces/IEvents.sol";
import "../libs/LibFixedMath.sol";
import "../libs/LibSafeMath.sol";
import "../libs/LibBondingCurve.sol";
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
        if (state.t == _getCurrentBlockNumber()) {
            state.fee = state.feeHigh;
        }

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
                LibToken.daiToFixed(amount),
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
        int256 pA = LibBondingCurve.computeMidpointPrice(
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
        emit Price2(price);
        */


        if (price < 0)  {
            revert('price cannot be < 0');
        } else if (price == 0) {
            revert('price cannot be zero');
        }

        // Compute about of `tokenB`


        int256 deltaB = deltaA
            .mul(price)
            .mul(
                LibFixedMath.one().sub(state.fee)
            );
        deltaB = -deltaB;

        if (deltaB >= 0) {
            revert('deltaB is greater or equal to zero');
        }

        // Edge Cases
        int256 epsilon = LibFixedMath.toFixed(int256(1), int256(100000));
        if (b.add(deltaB) <= epsilon) {
            deltaB = epsilon.sub(b);
            deltaB = (deltaB < 0) ? deltaB : 0;
        }

        // Round up to favor the contract
        // We impose a dust amount of 1/10^6. This is the minimum token amount.
        deltaB += LibFixedMath.toFixed(int256(1), int256(10**6));

        if (deltaB >= 0) {
            revert('Tried to purchase too much');
        }


        // Handle additional edge cases
        int256 newPBarA = LibBondingCurve.computeNewPBarA(
            state.t,
            _getCurrentBlockNumber(),
            state.beta,
            pA,
            pBarA
        );

        if (newPBarA > state.eToKappa.mul(pBarA)) {
            newPBarA = state.eToKappa.mul(pBarA);
        } else if(newPBarA.mul(state.eToKappa) < pBarA) {
            newPBarA = pBarA.div(state.eToKappa);
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
        int256 ratio = LibFixedMath.one().div(LibFixedMath.one().sub(state.rhoRatio));
        yl = rl.pow(ratio);

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
        int256 rhoRatio
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
        int256 ratio = LibFixedMath.one().div(LibFixedMath.one().sub(rhoRatio));
        int256 yBis = term1.pow(ratio);

        //
        int256 term2 = k12.sub(k8.mul(term1));
        if (yBis <= term2) {
            int256 newYh = rh.pow(ratio);
            return (
                term1,
                rh,
                yBis,
                newYh
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
    {
        if (rl < LibFixedMath.toFixed(int256(95), int256(100))) {
            revert('Order too large');
        }
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

    event VALUE(
        string description,
        int256 val
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



        //emit VALUE("delta after step0", delta);

        int256 rl = LibBondingCurve.computeMaximumPriceInDomain(
            a,
            b,
            pA,
            pBarA,
            deltaA,
            state
        );

        emit VALUE("rl after step 1", rl);

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

        emit VALUE("rh after step 2", rh);


        if (_shouldImprovePrecision(rl, rh, state.fee)) {
            int256 yl;
            (rh, yl) = _computeStep3(
                rl,
                rh,
                k8,
                k12,
                state
            );
            emit VALUE("rh after step 3", rh);
            emit VALUE("yl after step 3", yl);

            if (_shouldImprovePrecision(rl, rh, state.fee)) {
                int256 yh;
                (rl, rh, yl, yh) = _computeStep4(
                    rl,
                    rh,
                    k8,
                    k12,
                    yl,
                    state.rhoRatio
                );

                emit VALUE("rl after step 4", rl);
                emit VALUE("rh after step 4", rh);
                emit VALUE("yl after step 4", yl);
                emit VALUE("yh after step 4", yh);

                if (_shouldImprovePrecision(rl, rh, state.fee)) {
                    rl = _computeStep5(
                        rl,
                        rh,
                        yl,
                        yh,
                        k8,
                        k12
                    );

                    emit VALUE("rl after step 5", rl);
                }
            }
        }

        // Step 6
        _computeStep6(rl);

        emit VALUE("final price", rl.mul(pA));

        // Step 7
        return rl.mul(pA);
    }

    function _getCurrentBlockNumber()
        internal
        returns (uint256)
    {
        return block.number;
    }
}
