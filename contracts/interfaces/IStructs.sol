pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;


interface IStructs {

    struct State {
        address xAddress;                                   // address of token x
        address yAddress;                                   // address of token y
        int256 x;                                           // contract's balance of token x (fixed point)
        int256 y;                                           // contract's balance of token y (fixed point)
        uint256 l;                                          // total liquidity token balance
        int256 pBarX;                                       // expected future price of x in terms of y (fixed point)
        int256 pBarXInverted;                               // inverted expected future price of x in terms of y (fixed point)
        uint256 rhoNumerator;
        int256 rhoRatio;
        int256 fee;
        uint256 bisectionIterations;
        uint256 t;                                          // most recent block
        mapping (address => uint256) liquidityBalance;
    }

}
