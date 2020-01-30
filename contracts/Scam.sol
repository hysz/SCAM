pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

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
    Liquidity
{

    using LibFixedMath for int256;
    using LibAMM for IStructs.AMM;

    IStructs.BondingCurve public gCurve;
    uint256 public gBlockNumber;

    constructor()
        public
    {}

    modifier onlyERC20BridgeProxy() {
        _;
    }

    function bridgeTransferFrom()
        external
        onlyERC20BridgeProxy
    {

    }

    // Need an INIT or CONFIGURE or RESET


    function getQuote(
        address takerAsset,
        uint256 takerAssetAmount
    )
        external
        view
        returns (uint256 makerAssetAmount)
    {
        /*
        // Execute trade on the AMM model.
        (, makerAssetAmount) = _getAMM().trade(
            takerAsset,
            LibToken.tokenToFixed(takerAssetAmount, 18),
            _getCurrentBlockNumber()
        );
        */
    }

    function trade(
        address takerAsset,
        uint256 takerAssetAmount
    )
        public
        returns (uint256 makerAssetAmount)
    {
        // Execute trade on the AMM model.
        IStructs.AMM memory amm = _getAMM();
        int256 makerAssetAmountFixed = amm.trade(
            takerAsset,
            LibToken.daiToFixed(takerAssetAmount),
            _getCurrentBlockNumber()
        );
        makerAssetAmount = LibToken.tokenFromFixed(makerAssetAmountFixed, 18);

        // Save the updated AMM.
        _saveAMM(amm);

        /*
        // Emit Fill event.
        emit IEvents.Fill(
            msg.sender,
            takerAsset,
            takerAssetAmount,
            makerAssetAmount
        );
        */

        // Transfer maker asset
        //_settleTrade(amm);

        return makerAssetAmount;
    }

    function _settleTrade(IStructs.AssetPair memory assets)
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

    //function getAMM() external

    function _addLiquidity(int256 xAmount, int256 yAmount)
        internal
    {
        gCurve.xReserve = xAmount;
        gCurve.yReserve = yAmount;

        // DEPOSIT FUNDS
    }

    /// @dev Store persistent parameters.
    function _saveAMM(IStructs.AMM memory amm)
        internal
    {
        gCurve.xReserve = amm.curve.xReserve;
        gCurve.yReserve = amm.curve.yReserve;
        gCurve.expectedPrice = amm.curve.expectedPrice;
        gBlockNumber = amm.blockNumber;
    }

    function _getAMM()
        internal
        view
        returns (IStructs.AMM memory amm)
    {
        amm = _getDefaultAMM();
        amm.curve = gCurve;
        amm.blockNumber = gBlockNumber;
    }

    /// @dev To be implemented by the specific AMM.
    function _getDefaultAMM()
        internal
        view
        returns (IStructs.AMM memory);

    function _getCurrentBlockNumber()
        internal
        view
        returns (uint256)
    {
        return block.number;
    }
}
