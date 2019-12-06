pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
}
