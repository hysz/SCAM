pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;


interface IEvents {

    event Fill(
        address from,
       // address fromToken,
        //address toToken,
        uint256 amountSpent,
        uint256 amountReceived,

        int256 x,
        int256 y
    );
}
