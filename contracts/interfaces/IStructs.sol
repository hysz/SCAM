pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;


interface IStructs {

    struct State {
        uint256 x;                                          // contract's balance of token x
        uint256 y;                                          // contract's balance of token y
        uint256 pHatX;                                      // expected future price of x in terms of y
        uint256 t;                                          // most recent block
        mapping (address => uint256) liquidityBalance;
        uint256 l;                                          // total liquidity token balance
    }

}
