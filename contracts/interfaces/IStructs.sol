pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;


interface IStructs {

    struct AssetPair {
        address xAsset;
        address yAsset;
    }

    struct BondingCurve {
        int256 xReserve;
        int256 yReserve;
        int256 expectedFuturePrice;
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

    ///
    struct State {
        IStructs.AssetPair assets;
        IStructs.BondingCurve curve;



        bool isInitialized;
        //address xAddress;                                   // address of token x
        //address yAddress;                                   // address of token y
        //int256 x;                                           // contract's balance of token x (fixed point)
        //int256 y;                                           // contract's balance of token y (fixed point)
        uint256 l;                                          // total liquidity token balance
        //int256 pBarX;                                       // expected future price of x in terms of y (fixed point)
        //uint256 rhoNumerator;
        //int256 rhoRatio;
        int256 fee;
        int256 feeHigh;
        uint256 t;                                          // most recent block
        mapping (address => uint256) liquidityBalance;
        int256 beta;    // persistence of expercted price - the larger the more persistent
        int256 eToKappa;   // clamp that prevents the expected price changing by a lot in an expected tx
    }

}
