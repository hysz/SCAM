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
        State()
        Liquidity()
        Swapper()
    {}
}
