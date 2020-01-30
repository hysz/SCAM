pragma solidity ^0.5.9;

import "./LibFixedMath.sol";


library LibToken {

    using LibFixedMath for int256;

    uint256 private constant WETH_DECIMALS = 18;
    uint256 private constant DAI_DECIMALS = 18;
    uint256 private constant USDC_DECIMALS = 6;

    function tokenToFixed(uint256 amount, uint256 nDecimals)
        internal
        pure
        returns (int256 fixedAmount)
    {
        return LibFixedMath.toFixed(amount, 10**nDecimals);
    }

    function tokenFromFixed(int256 amount, uint256 nDecimals)
        internal
        pure
        returns (uint256 tokenAmount)
    {
        return uint256((amount * int256(10**nDecimals)).toInteger());
    }

    function daiToFixed(uint256 amount)
        internal
        pure
        returns (int256 fixedAmount)
    {
        return tokenToFixed(amount, DAI_DECIMALS);
    }

    function daiFromFixed(int256 amount)
        internal
        pure
        returns (uint256 tokenAmount)
    {
        return tokenFromFixed(amount, DAI_DECIMALS);
    }

    function usdcToFixed(uint256 amount)
        internal
        pure
        returns (int256 fixedAmount)
    {
        return tokenToFixed(amount, USDC_DECIMALS);
    }

    function usdcFromFixed(int256 amount)
        internal
        pure
        returns (uint256 tokenAmount)
    {
        return tokenFromFixed(amount, USDC_DECIMALS);
    }
}
