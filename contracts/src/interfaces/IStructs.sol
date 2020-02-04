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
pragma experimental ABIEncoderV2;


interface IStructs {

    struct AssetPair {
        address xAsset;
        address yAsset;
        uint8 xDecimals;
        uint8 yDecimals;
    }

    struct BondingCurve {
        int256 xReserve;
        int256 yReserve;
        int256 expectedPrice;
        int256 slippage;
    }

    /// @dev  A point (x,y). This encapsulates a point on the Bonding Curve.
    /// @param x the x-coordinate.
    /// @param y the y-coordinate.
    struct Point {
        int256 x;
        int256 y;
    }

    struct Domain {
        int256 x;
        int256 delta;
    }

    struct PriceRange {
        int256 min;
        int256 max;
    }

    /// @dev Fee paid on each trade. Each value is a percentage (range [0..1]).
    ///      There is a low fee and high fee, which are applied in difference trade scenarios.
    ///      See `LibAMM` for implementation details on how the fee is applied.
    struct Fee {
        int256 lo;
        int256 hi;
    }

    /// @dev Constraints used when setting the expected future price.
    /// @param persistence This value must be in the range (0,1]. A persistence of 1 means that the
    ///                    expected price never changes. A lower value results in more volatile changes
    ///                    to the expected price.
    ///                    Note: this is `beta` in the whitepaper.
    /// @param variability This is the maximum allowed log-percent change in expected price.
    ///                    This value must be a real number ≥0.
    ///                    Note: this is `exp(kappa)` in the whitepaper.
    struct PriceConstraints {
        int256 persistence;
        int256 variability;
    }

    struct AMM {
        AssetPair assets;
        BondingCurve curve;
        Fee fee;
        PriceConstraints constraints;
        int256 blockNumber;
    }
}
