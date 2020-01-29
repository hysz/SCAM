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
    using LibBondingCurve for IStructs.BondingCurve;

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

        if (fromToken == state.assets.xAsset) {
            int256 amountReceivedFixed = _swap(
                fromToken,
                LibToken.daiToFixed(amount),
                state
            );
            amountReceived = LibToken.usdcFromFixed(amountReceivedFixed);
        } else {
            int256 amountReceivedFixed = _swap(
                fromToken,
                LibToken.daiToFixed(amount),
                state
            );
            amountReceived = LibToken.daiFromFixed(amountReceivedFixed);
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

        // //emit event
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
        address takerAsset,
        int256 deltaA,
        IStructs.State memory state
    )
        internal
        returns (int256 amountReceived)
    {


        // Transform stored curve for this trade.
        IStructs.BondingCurve memory curve = LibBondingCurve.transformStoredBondingCurveForTrade(
            state.curve,
            state.assets,
            takerAsset
        );

        bool fromIsX = state.curve.expectedFuturePrice == curve.expectedFuturePrice;

        // Compute initial midpoint on bond curve; this will be the initial lower bound.
        int256 pA = curve.computeMidpointPrice();
        int256 rl = curve.computeMaximumPriceInDomain(
            IStructs.Domain({x: curve.xReserve, delta: deltaA}),
            pA
        );

        // Compute
        int256 price = _bracket(
            curve,
            pA,
            deltaA,
            rl,
            state.fee
        );

         // Step 6
        _computeStep6(price);

        //emit VALUE("final price", rl.mul(pA));

        // Step 7
        price = price.mul(pA);


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
        if (curve.yReserve.add(deltaB) <= epsilon) {
            deltaB = epsilon.sub(curve.yReserve);
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
            curve.expectedFuturePrice
        );

        if (newPBarA > state.eToKappa.mul(curve.expectedFuturePrice)) {
            newPBarA = state.eToKappa.mul(curve.expectedFuturePrice);
        } else if(newPBarA.mul(state.eToKappa) < curve.expectedFuturePrice) {
            newPBarA = curve.expectedFuturePrice.div(state.eToKappa);
        }

        // Update state
        state.t = _getCurrentBlockNumber();
        if (fromIsX) {
            curve.xReserve = curve.xReserve.add(deltaA);
            curve.yReserve = curve.yReserve.add(deltaB);
            curve.expectedFuturePrice = newPBarA;
        } else {
            curve.xReserve = curve.yReserve.add(deltaB);
            curve.yReserve = curve.xReserve.add(deltaA);
            curve.expectedFuturePrice = LibFixedMath.one().div(newPBarA);
            //curve.slippage
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

    function _computeStep2(
        IStructs.BondingCurve memory curve,
        int256 pA,
        int256 deltaA,
        int256 k8,
        int256 k12
    )
        internal
        returns (int256)
    {
        int256 a = curve.xReserve;
        int256 b = curve.yReserve;
        int256 pBarA = curve.expectedFuturePrice;
        int256 rhoRatio = curve.slippage;

        int256 term1 = k12.div(k8);
        int256 term2 = rhoRatio.add(
            LibFixedMath.one()
            .sub(rhoRatio)
            .mul(k12)
        );
        int256 term3 = LibFixedMath.one().add(
            LibFixedMath.one()
            .sub(rhoRatio)
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
        int256 rhoRatio
    )
        internal
        returns (int256 newRh, int256 yl)
    {
        int256 ratio = LibFixedMath.one().div(LibFixedMath.one().sub(rhoRatio));
        yl = rl.pow(ratio);

        int256 term1 = rhoRatio.mul(yl)
            .add(
                LibFixedMath.one()
                .sub(rhoRatio)
                .mul(k12)
            );
        int256 term2 = yl
            .add(
                LibFixedMath.one()
                .sub(rhoRatio)
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
            newRl = term1;
            newRh = rh;
            newYl = yBis;
            newYh = rh.pow(ratio);
        } else {
            newRl = rl;
            newRh = term1;
            newYl = yl;
            newYh = yBis;
       }

       return (
           newRl,
           newRh,
           newYl,
           newYh
       );
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

        //emit L(lhs,rhs);

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
        IStructs.BondingCurve memory curve,
        int256 pA,
        int256 deltaA,
        int256 rl,
        int256 fee
    )
        internal
        returns (int256)
    {
        // Cache constants that are used throughout bracketing algorithm.
        int256 k8 = curve.xReserve.mul(
            pA
            .mul(deltaA)
            .div(curve.xReserve.mul(curve.yReserve).add(curve.yReserve.mul(deltaA)))
        );
        int256 k12 = curve.xReserve.div(
            curve.xReserve.add(deltaA)
        );

        int256 rh = _computeStep2(
            curve,
            pA,
            deltaA,
            k8,
            k12
        );

        //emit VALUE("rh after step 2", rh);


        if (!_shouldImprovePrecision(rl, rh, fee)) {
            return rl;
        }

        int256 yl;
        (rh, yl) = _computeStep3(
            rl,
            rh,
            k8,
            k12,
            curve.slippage
        );
            //emit VALUE("rh after step 3", rh);
            //emit VALUE("yl after step 3", yl);

        if (!_shouldImprovePrecision(rl, rh, fee)) {
            return rl;
        }

        int256 slippage = curve.slippage;

        int256 yh;
        (rl, rh, yl, yh) = _computeStep4(
            rl,
            rh,
            k8,
            k12,
            yl,
            slippage
        );

        //emit VALUE("rl after step 4", rl);
        //emit VALUE("rh after step 4", rh);
        //emit VALUE("yl after step 4", yl);
        //emit VALUE("yh after step 4", yh);

        if (!_shouldImprovePrecision(rl, rh, fee)) {
            return rl;
        }

        rl = _computeStep5(
            rl,
            rh,
            yl,
            yh,
            k8,
            k12
        );

        return rl;

        //emit VALUE("rl after step 5", rl);
    }

    function _getCurrentBlockNumber()
        internal
        returns (uint256)
    {
        return block.number;
    }
}
