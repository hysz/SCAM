pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "./core/State.sol";
import "./core/Liquidity.sol";
import "./interfaces/IStructs.sol";
import "./interfaces/IEvents.sol";
import "./libs/LibFixedMath.sol";
import "./libs/LibSafeMath.sol";
import "./libs/LibBondingCurve.sol";
import "./libs/LibToken.sol";
import "./libs/LibAMM.sol";
import "./interfaces/IERC20.sol";


contract Scam is
    IEvents,
    State,
    Liquidity
{

    constructor()
        public
    {}

/*
    function bridgeTransferFrom()
        external
        onlyERC20BridgeProxy
    {

    }

    function getQuote


    function

    function

    function _settleBalances()
        internal
    {}

*/

    using LibFixedMath for int256;
    using LibBondingCurve for IStructs.BondingCurve;

    event Price(int256 price, int256 deltaB, int256 newPBarX, int256 pA);

    event Price2(int256 price);

    function swap(
        address fromToken,
        address toToken,
        uint256 amount
    )
        public
        returns (uint256 amountReceived)
    {
        IStructs.State memory state = _loadGlobalState();
        if (fromToken == state.assets.xAsset) {
            int256 amountReceivedFixed;
            (amountReceivedFixed, state) = LibAMM.computeAmountBought(
                fromToken,
                LibToken.daiToFixed(amount),
                state,
                _getCurrentBlockNumber()
            );
            amountReceived = LibToken.usdcFromFixed(amountReceivedFixed);
        } else {
            int256 amountReceivedFixed;
            (amountReceivedFixed, state) = LibAMM.computeAmountBought(
                fromToken,
                LibToken.daiToFixed(amount),
                state,
                _getCurrentBlockNumber()
            );
            amountReceived = LibToken.daiFromFixed(amountReceivedFixed);
        }

        _settleTrade();

        _saveGlobalState(state);

        // //emit event
        emit IEvents.Fill(
            msg.sender,
            fromToken,
            toToken,
            amount,
            amountReceived
        );

        return amountReceived;
    }

    function _settleTrade()
        internal
    {
        // Make transfers
        /*
        require(
            IERC20(fromToken).transferFrom(msg.sender, address(this), amount),
            'INSUFFICIENT_FROM_TOKEN_BALANCE'
        );
        require(
            // IERC20(toToken).transferFrom(address(this), msg.sender, amountReceived),
            IERC20(toToken).transfer(msg.sender, amountReceived),
            'INSUFFICIENT_TO_TOKEN_BALANCE'
        );
        */
    }

    function _getCurrentBlockNumber()
        internal
        returns (uint256)
    {
        return block.number;
    }
}
