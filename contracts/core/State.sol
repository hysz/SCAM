pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../interfaces/IStructs.sol";
import "../libs/LibFixedMath.sol";
import "./Ownable.sol";


contract State is
    Ownable
{

    using LibFixedMath for int256;

    IStructs.State public gState;

    function _loadGlobalState()
        internal
        returns (IStructs.State memory state)
    {
        state = gState;
        return state;
    }

    function _saveGlobalState(IStructs.State memory state)
        internal
    {
        gState.curve = state.curve;
        gState.t = state.t;
    }
}
