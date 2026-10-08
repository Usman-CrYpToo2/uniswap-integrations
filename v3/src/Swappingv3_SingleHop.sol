// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "v3-periphery/interfaces/ISwapRouter.sol";
import "v3-periphery/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Swappingv3_SingleHop {
    ISwapRouter public constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint24 public constant poolFee = 3000; // WETH/DAI 0.3% pool

    function singleHopSwapWethForDaiExactInput(uint256 amountIn) external returns (uint256) {
        TransferHelper.safeTransferFrom(WETH9, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(WETH9, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH9,
            tokenOut: DAI,
            fee: poolFee,
            recipient: msg.sender,
            deadline: block.timestamp + 1000,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        uint256 amountout = swapRouter.exactInputSingle(params);
        return amountout;
    }

    function singleHopSwapWethForDaiExactOutput(uint256 Token1_AmountOut, uint256 Token0_MaximumAmountIn)
        external
        returns (uint256)
    {
        TransferHelper.safeTransferFrom(WETH9, msg.sender, address(this), Token0_MaximumAmountIn);
        TransferHelper.safeApprove(WETH9, address(swapRouter), Token0_MaximumAmountIn);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: WETH9,
            tokenOut: DAI,
            fee: poolFee,
            recipient: msg.sender,
            deadline: block.timestamp + 1000,
            amountOut: Token1_AmountOut,
            amountInMaximum: Token0_MaximumAmountIn,
            sqrtPriceLimitX96: 0
        });

        uint256 amountIn = swapRouter.exactOutputSingle(params);

        if (Token0_MaximumAmountIn > amountIn) {
            TransferHelper.safeApprove(WETH9, address(swapRouter), 0);
            TransferHelper.safeTransfer(WETH9, msg.sender, Token0_MaximumAmountIn - amountIn);
        }

        return amountIn;
    }
}
