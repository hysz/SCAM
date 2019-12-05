pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "./core/State.sol";
import "./core/Liquidity.sol";
import "./core/Swapper.sol";


contract Scam is
    State,
    Liquidity,
    Swapper
{

    constructor()
        // State()
        // Liquidity()
        // Swapper()
        public
    {}

    function init(uint256 rhoNumerator, uint256 rhoDenominator)
        external
        // onlyOwner
    {
        // We require this for fast multiplication.
        require(
            rhoDenominator == (rhoNumerator + 1),
            "Invalid value for rho"
        );

        gState.rhoRatio = LibFixedMath.toFixed(rhoNumerator, rhoDenominator);
    }
}
