/*
  Copyright 2017 Bprotocol Foundation, 2019 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.5.9;

import "../interfaces/IStructs.sol";
import "./LibFixedMath.sol";


library LibBondingCurve {

    using LibFixedMath for int256;

    /// @dev This returns the price at a specific point (a,b) on the token bond curve,
    ///      which is defined by the slope of the tangent at (a,b).
    function computeMidpointPrice(
        int256 a,
        int256 b,
        int256 pBarA,
        int256 rhoRatio
    )
        internal
        pure
        returns (int256 price)
    {
        int256 term1 = b.div(pBarA.mul(a));
        int256 term2 = term1.pow(
            LibFixedMath.one()
            .sub(rhoRatio)
        );
        price = pBarA.mul(term2);
        return price;
    }

    /// @dev Computes the expected future price of token `a` in terms of token `b`.
    function computeNewPBarA(
        uint256 t,
        uint256 newT,
        int256 beta,
        int256 pA,
        int256 pBarA
    )
        internal
        pure
        returns (int256)
    {
        int256 deltaT = LibFixedMath.toFixed(newT - t);
        int256 betaToDeltaT = beta.pow(deltaT);
        int256 oneMinusBToDeltaT = LibFixedMath.one().sub(betaToDeltaT);
        int256 term1 = pA.mul(oneMinusBToDeltaT);
        int256 term2 = pBarA.mul(betaToDeltaT);

        int256 term3Denominator = LibFixedMath.add(
            oneMinusBToDeltaT.mul(pBarA),
            betaToDeltaT.mul(pA)
        );
        int256 term3 = pA.mul(pBarA).div(term3Denominator);
        int256 result = term1.add(term2).add(term3).div(LibFixedMath.two());
        return result;
    }


    /// @dev Computes the highest price to sell token `b` in the range [a, a + deltaA].
    ///
    ///      Implementation Note: This
    function computeMaximumPriceInDomain(
        int256 a,
        int256 b,
        int256 pA,
        int256 pBarA,
        int256 deltaA,
        IStructs.State memory state
    )
        internal
        pure
        returns (int256)
    {
        int256 delta = computeOffsetToMaximumPriceInDomain(
            a,
            b,
            pA,
            pBarA,
            deltaA,
            state
        );

        int256 term1 = a.mul(b.sub(delta.mul(pA)));
        int256 term2 = b.mul(a.add(delta));
        int256 term3 = term1.div(term2);
        int256 term4 = term3.pow(LibFixedMath.one().sub(state.rhoRatio));
        int256 term5 = term4.mul(delta).div(deltaA);
        return term5;
    }

    /// @dev Computes the offset to the highest price to sell token `b` in the range [a, a + deltaA].
    ///      To do this we find the nearest local maxima, which is defined as
    ///      the point where the first derivative is zero and the second derivative
    ///      is decreasing. If this point is greater than the domain limit of `a + deltaA`,
    ///      then the maximum price is at `a + deltaA`.
    function computeOffsetToMaximumPriceInDomain(
        int256 a,
        int256 b,
        int256 pA,
        int256 pBarA,
        int256 deltaA,
        IStructs.State memory state
    )
        internal
        pure
        returns (int256)
    {
        int256 k13 = LibFixedMath.two()
            .sub(state.rhoRatio)
            .mul(a)
            .mul(pA)
            .sub(state.rhoRatio.mul(b));

        int256 term1 = k13.square().add(
            LibFixedMath.four()
            .mul(pA)
            .mul(a)
            .mul(b)
        );

        int256 term2 = (-k13)
            .add(term1.sqrt())
            .div(
                LibFixedMath.two()
                .mul(pA)
            );

        int256 delta = LibFixedMath.min(deltaA, term2);
        return delta;
    }


}