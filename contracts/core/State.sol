pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../interfaces/IStructs.sol";
import "../libs/LibFixedMath.sol";
import "../libs/LibScamMath.sol";
import "./Ownable.sol";


contract State is
    Ownable
{

    using LibFixedMath for int256;

    IStructs.State public gState;

    function initState(address xAddress, address yAddress)
        external
        onlyOwner
    {
        _initState(xAddress, yAddress);
    }

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
        gState.x = state.x;
        gState.y = state.y;
        gState.pBarX = state.pBarX;
        gState.t = state.t;
    }

    function _initState(address xAddress, address yAddress)
        internal
    {
        require(
            !gState.isInitialized,
            'Already Initialized'
        );

        gState.xAddress = xAddress;
        gState.yAddress = yAddress;
        gState.pBarX = LibFixedMath.toFixed(uint256(99), uint256(100));  // initial expected price of X given Y
        gState.rhoNumerator = uint256(99);
        gState.rhoRatio = LibFixedMath.toFixed(uint256(99), uint256(100));
        gState.fee = LibFixedMath.toFixed(uint256(5), uint256(10000));    // 0.0005
        gState.beta = LibFixedMath.one().sub(
            LibFixedMath.toFixed(int256(1), int256(1000000))
        );
        gState.eToKappa = LibFixedMath.toFixed(int256(10005), int256(1000));
        gState.isInitialized = true;
    }
}
