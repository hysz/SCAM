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
import "./LibBondingCurve.sol";


library LibRootFinding {

    using LibFixedMath for int256;

    event VALUE(
        string description,
        int256 val
    );

    function bracket(
        IStructs.BondingCurve memory curve,
        int256 pA,
        int256 deltaA,
        int256 rl,
        int256 fee
    )
        internal
        returns (int256)
    {

        rl = rl.div(pA);

        // Cache constants that are used throughout bracketing algorithm.
        int256 k8 = curve.xReserve.mul(
            pA
            .mul(deltaA)
            .div(curve.xReserve.mul(curve.yReserve).add(curve.yReserve.mul(deltaA)))
        );
        int256 k12 = curve.xReserve.div(
            curve.xReserve.add(deltaA)
        );

        emit VALUE("rl after step 1", rl);

        int256 rh = _computeStep2(
            curve,
            pA,
            deltaA,
            k8,
            k12
        );

        emit VALUE("rh after step 2", rh);


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

        emit VALUE("rh after step 3", rh);
        emit VALUE("yl after step 3", yl);

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

        emit VALUE("rl after step 4", rl);
        emit VALUE("rh after step 4", rh);
        emit VALUE("yl after step 4", yl);
        emit VALUE("yh after step 4", yh);

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

        emit VALUE("rl after step 5", rl);
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
        int256 pBarA = curve.expectedPrice;
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

}
