pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "./LibFixedMath.sol";

library LibScamMath {

    using LibFixedMath for int256;

    /// @dev computes midpoint, inputs are all fixed point values.
    function computeMidpointOnBondCurve(
        int256 pBarA,
        int256 b,
        int256 rhoRatio
    )
        internal
        returns (int256 midpoint)
    {
        return pBarA.mul(
            LibFixedMath.one().sub(rhoRatio)
            .mul(b.div(pBarA).ln())
            .exp()
        );
        /*
        return pBarA.mul(
            b.div(pBarA)
            .exp(LibFixedMath.one().sub(rhoRatio))
        );
        */
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

    /// @dev Hardcoded for rhoNumerator = 99
    function computeBaseToNinetyNine(
        int256 base
    )
        internal
        returns (int256)
    {
        // Hack.gif ToDaMoon.gif TopKek.gif
        int256 baseSquared = base.mul(base);
        int256 baseCubed = base.mul(baseSquared);
        int256 baseToSix = baseCubed.mul(baseCubed);
        int256 baseToTwelve = baseToSix.mul(baseToSix);
        int256 baseToTwentyFour = baseToTwelve.mul(baseToTwelve);
        int256 baseToFourtyEight = baseToTwentyFour.mul(baseToTwentyFour);
        int256 baseToNinetySix = baseToFourtyEight.mul(baseToFourtyEight);
        int256 baseToNinetyNine = baseToNinetySix.mul(baseCubed);
        return baseToNinetyNine;
    }
}
