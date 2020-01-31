pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;


interface IEvents {

    event Fill(
        address from,
        address fromToken,
        address toToken,
        uint256 amountSpent,
        uint256 amountReceived
    );

    event FillInternal(
        address from,
        int256 amountSpent,
        int256 amountReceived
    );
}
