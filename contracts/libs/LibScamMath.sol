pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "./LibFixedMath.sol";

library LibScamMath {

    using LibFixedMath for int256;

    event TestMidpointOnBondCurve(
        int256 a,
        int256 b,
        int256 pBarA,
        int256 rhoRatio,
        int256 result
    );

    /// @dev computes midpoint, inputs are all fixed point values.
    function computeMidpointOnBondCurve(
        int256 a,
        int256 b,
        int256 pBarA,
        int256 rhoRatio
    )
        internal
        returns (int256 result)
    {
        int term0 = pBarA.mul(a);
        int term1A = b.div(term0);
        int term1B = term0.div(b);
        int term2 = LibFixedMath.one().sub(rhoRatio);
        int256 term3;
        if (term1A < LibFixedMath.one()) {
            term3 = term1A.ln().mul(term2).exp();
        } else {
            term3 = LibFixedMath.one().div(
                term1B.ln().mul(term2).exp()
            );
        }
        result = term3.mul(pBarA);

/*
        emit TestMidpointOnBondCurve(
            a,
            b,
            pBarA,
            rhoRatio,
            result.toInteger()
        );
        */

        return result;
    }

    function computeNewPBarA(
        uint256 t,
        uint256 newT,
        int256 beta,
        int256 pA,
        int256 pBarA
    )
        internal
        returns (int256)
    {
        int256 deltaT = LibFixedMath.toFixed(newT - t);
        int256 betaToDeltaT = deltaT.mul(beta.ln()).exp();
        int256 oneMinusBToDeltaT = LibFixedMath.one().sub(betaToDeltaT);
        int256 term1 = pA.mul(oneMinusBToDeltaT);
        int256 term2 = pBarA.mul(betaToDeltaT);

        int256 term3Denominator = LibFixedMath.add(
            oneMinusBToDeltaT.mul(pBarA),
            betaToDeltaT.mul(pA)
        );
        int256 term3 = pA.mul(pBarA).div(term3Denominator);
        int256 result = term1.add(term2).add(term3).div(LibFixedMath.toFixed(int256(2)));
        return result;
    }

    function computeMidpoint(
        int256 a,
        int256 b
    )
        internal
        returns (int256 midpoint)
    {
        return a.add(b).div(LibFixedMath.one().add(LibFixedMath.one())); // @todo store FIXED_2 as a constant.
    }

    function tokenToFixed(uint256 amount, uint256 nDecimals)
        internal
        pure
        returns (int256 fixedAmount)
    {
        return LibFixedMath.toFixed(amount, 10**nDecimals);
    }

    function tokenFromFixed(int256 amount, uint256 nDecimals)
        internal
        pure
        returns (uint256 tokenAmount)
    {
        return uint256((amount * int256(10**nDecimals)).toInteger());
    }
}
