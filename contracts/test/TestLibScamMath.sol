pragma solidity ^0.5.9;

import "../libs/LibScamMath.sol";


contract TestLibScamMath {

    using LibScamMath for uint256;

    function fastExpontentiationFn(
        uint256 x,
        uint256 y
    )
        external
        pure
        returns (uint256)
    {
        return x.fastExponentiation(y);
    }
}
