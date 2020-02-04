pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../interfaces/IStructs.sol";
import "../interfaces/IEvents.sol";
import "../libs/LibFixedMath.sol";
import "../libs/LibBondingCurve.sol";
import "../libs/LibAMM.sol";
import "../interfaces/IERC20.sol";


contract AbstractAMM is
    IEvents
{

    using LibFixedMath for int256;
    using LibAMM for IStructs.AMM;

    // The token bonding curve. This is updated after each trade.
    IStructs.BondingCurve internal _gCurve;

    // The most recent block number. This is updated after each trade.
    // This is a fixed-point value (to reduce conversions during computation).
    int256 internal _gBlockNumber;

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
            _tokenToFixed(takerAssetAmount, 18),
            _getCurrentBlockNumber()
        );
        makerAssetAmount = _tokenFromFixed(makerAssetAmountFixed, 18);

        // Save the updated AMM.
        _saveAMM(amm);

        // Emit Fill event.
        /*
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
        // Execute trade on the AMM model, but don't save the result or settle funds.
        makerAssetAmount = _getAMM().trade(
            takerAsset,
            LibToken.tokenToFixed(takerAssetAmount, 18),
            _getCurrentBlockNumber()
        );
        */
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

    function _tokenToFixed(uint256 amount, uint256 nDecimals)
        internal
        pure
        returns (int256 fixedAmount)
    {
        return LibFixedMath.toFixed(amount, 10**nDecimals);
    }

    function _tokenFromFixed(int256 amount, uint256 nDecimals)
        internal
        pure
        returns (uint256 tokenAmount)
    {
        return uint256((amount * int256(10**nDecimals)).toInteger());
    }

    //function getAMM() external

    function _addLiquidity(int256 xAmount, int256 yAmount)
        internal
    {
        _gCurve.xReserve = xAmount;
        _gCurve.yReserve = yAmount;

        // DEPOSIT FUNDS
    }

    /// @dev Store persistent parameters.
    function _saveAMM(IStructs.AMM memory amm)
        internal
    {
        _gCurve.xReserve = amm.curve.xReserve;
        _gCurve.yReserve = amm.curve.yReserve;
        _gCurve.expectedPrice = amm.curve.expectedPrice;
        _gBlockNumber = amm.blockNumber;
    }

    function _getAMM()
        internal
        view
        returns (IStructs.AMM memory amm)
    {
        amm = _getDefaultAMM();
        amm.curve = _gCurve;
        amm.blockNumber = _gBlockNumber;
    }

    /// @dev To be implemented by the specific AMM.
    function _getDefaultAMM()
        internal
        view
        returns (IStructs.AMM memory);

    /// @dev Returns the current block number as a fixed-point value.
    function _getCurrentBlockNumber()
        internal
        view
        returns (int256)
    {
        uint256 unsignedBlockNumber = block.number;
        int256 blockNumber = int256(unsignedBlockNumber);
        if (uint256(blockNumber) != unsignedBlockNumber) {
            revert("Invalid block number.");
        }
        return LibFixedMath.toFixed(blockNumber);
    }
}
