pragma solidity ^0.5.9;

import "../libs/LibScamMath.sol";


library LibToken {

    uint256 private constant DAI_DECIMALS = 18;
    uint256 private constant USDC_DECIMALS = 6;

    function daiToFixed(uint256 amount)
        internal
        pure
        returns (int256 fixedAmount)
    {
        return LibScamMath.tokenToFixed(amount, DAI_DECIMALS);
    }

    function daiFromFixed(int256 amount)
        internal
        pure
        returns (uint256 tokenAmount)
    {
        return LibScamMath.tokenFromFixed(amount, DAI_DECIMALS);
    }

    function usdcToFixed(uint256 amount)
        internal
        pure
        returns (int256 fixedAmount)
    {
        return LibScamMath.tokenToFixed(amount, USDC_DECIMALS);
    }

    function usdcFromFixed(int256 amount)
        internal
        pure
        returns (uint256 tokenAmount)
    {
        return LibScamMath.tokenFromFixed(amount, USDC_DECIMALS);
    }
}