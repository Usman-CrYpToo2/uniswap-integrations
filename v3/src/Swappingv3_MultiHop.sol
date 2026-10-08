// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "v3-periphery/interfaces/ISwapRouter.sol";
import "v3-periphery/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Swappingv3_MultiHop {
    ISwapRouter public constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint24 public constant poolFee = 3000;
    uint24 public constant poolFee2 = 100;

    function multiHopSwapWethForDaiExactInput(uint256 amountIn) external returns(uint256) {
         TransferHelper.safeTransferFrom(WETH9, msg.sender, address(this), amountIn);
         TransferHelper.safeApprove(WETH9, address(swapRouter), amountIn);

         ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
             path: abi.encodePacked(WETH9, poolFee,USDT, poolFee, DAI),
             recipient: msg.sender,
             deadline: block.timestamp + 1000,
             amountIn: amountIn,
                amountOutMinimum: 0
         });

         uint256 amountOut = swapRouter.exactInput(params);
         return amountOut;
    }

    function multiHopSwapWethForDaiExactOutput(uint256 Token1_AmountOut, uint256 Token0_MaximumAmountIn) external returns(uint256) {
         TransferHelper.safeTransferFrom(WETH9, msg.sender, address(this), Token0_MaximumAmountIn);
         TransferHelper.safeApprove(WETH9, address(swapRouter), Token0_MaximumAmountIn);

         ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
             path: abi.encodePacked(DAI, poolFee2, USDC, poolFee2, WETH9),
             recipient: msg.sender,
             deadline: block.timestamp + 1000,
            amountOut: Token1_AmountOut,
            amountInMaximum: Token0_MaximumAmountIn
         });

         uint256 amountIn = swapRouter.exactOutput(params);
         
         if(Token0_MaximumAmountIn > amountIn) {
             TransferHelper.safeApprove(WETH9, address(swapRouter), 0);
             TransferHelper.safeTransferFrom(WETH9, address(this), msg.sender, Token0_MaximumAmountIn - amountIn);
         }

         return amountIn;
    }
}

