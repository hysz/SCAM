pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;


interface IStructs {

    struct AssetPair {
        address xAsset;
        address yAsset;
        int256 xDecimals;
        int256 yDecimals;
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

    ///
    struct State {
        IStructs.AssetPair assets;
        IStructs.BondingCurve curve;
        uint256 t;                                          // most recent block
    }

    struct AMM {
        AssetPair assets;
        BondingCurve curve;
        Fee fee;
        PriceConstraints constraints;
        int256 blockNumber;
    }
}
