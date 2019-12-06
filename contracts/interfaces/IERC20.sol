pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address, uint256) external returns (bool);

}
