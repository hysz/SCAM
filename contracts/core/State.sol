pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../interfaces/IStructs.sol";
import "../libs/LibFixedMath.sol";
import "../libs/LibScamMath.sol";


contract State {

    IStructs.State gState;

    //// HACKY WORKAROUND 'TIL WE FIX THE FIXED MATH LIB

    function _loadGlobalState()
        internal
        returns (IStructs.State memory state)
    {
        state = gState;

/*
        state.x = LibScamMath.scaleDown(state.x);
        state.y = LibScamMath.scaleDown(state.y);
        state.pBarX = LibScamMath.scaleDown(state.pBarX);

        state.rhoRatio = LibScamMath.scaleDown(state.rhoRatio);
        state.fee = LibScamMath.scaleDown(state.fee);
*/

        return state;
    }

    function _saveGlobalState(IStructs.State memory state)
        internal
    {
/*
        gState.x = LibScamMath.scaleUp(state.x);
        gState.y = LibScamMath.scaleUp(state.y);
        gState.pBarX = LibScamMath.scaleUp(state.pBarX);
*/

        gState = state;
    }

}
