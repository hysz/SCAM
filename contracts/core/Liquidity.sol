pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../libs/LibSafeMath.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IStructs.sol";


/// FIXME(jalextowle): Add in the bias factor and ponzi scheme
contract Liquidity is
    IStructs
{
    using LibSafeMath for uint256;

    /// @dev Allows a sender to deposit tokens into the contract to provide liquidity.
    /// @param x_amount The amount of x that should be taken from the sender's balance.
    /// @param y_amount The amount of x that should be taken from the sender's balance.
    function addLiquidity(uint256 x_amount, uint256 y_amount)
        external
    {
        // Load the contract's state.
        IStructs.State memory state = gState;

        // Ensure that the amount of x and y that are being deposited are proportional.
        require(
            x_amount.safeMul(state.y) == y_amount.safeMul(state.x),
            "Liquidty:Amount deposited not proportional"
        );

        // Charge the sender the amount of x and y tokens that were specified
        IERC20(state.xAddress).transferFrom(msg.sender, address(this), x_amount);
        IERC20(state.yAddress).transferFrom(msg.sender, address(this), y_amount);

        // Grant the sender some liquidity tokens.
        // FIXME(jalextowle): (Look into whether more precision is needed)
        uint256 liquidity_reward = x_amount.safeMul(state.l).safeDiv(state.x);

        // Increase the balances of x and y
        state.x = state.x.safeAdd(x_amount);
        state.y = state.y.safeAdd(y_amount);

        // Grant the liquidity tokens
        state.liquidityBalance[msg.sender] = state.liquidityBalance[msg.sender].safeAdd(
            liquidity_reward
        );
        state.l = state.l.safeAdd(liquidity_reward);
    }

    /// @dev Allows a sender to withdraw tokens by burning liquidity tokens.
    /// @param The amount of liquidity tokens to burn.
    function removeLiquidity(uint256 l_amount)
        external
    {
        // Load the contract's state.
        IStructs.State memory state = gState;

        // Calculate the amounts of tokens that should be sent to the sender.
        uint256 x_amount = amount.safeMul(state.x).safeDiv(state.l);
        uint256 y_amount = amount.safeMul(state.y).safeDiv(state.l);

        // Decrease the balances of x and y
        state.x = state.x.safeSub(x_amount);
        state.y = state.y.safeSub(y_amount);

        // Destroy the liquidity tokens
        state.liquidityBalance[msg.sender] = state.liquidityBalance[msg.sender].safeSub(
            l_amount
        );
        state.l = state.l.safeAdd(l_amount);

        // Reward sender in the correct amounts of x and y.
        IERC20(state.xAddress).transfer(msg.sender, x_amount);
        IERC20(state.yAddress).transfer(msg.sender, y_amount);
    }
}
