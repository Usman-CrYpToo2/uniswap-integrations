// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0;
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract Swapping {

     ISwapRouter private immutable swapRouter; 
     IERC20 private immutable WETH9;
     
     constructor(ISwapRouter contractSwap, IERC20 contractWeth9){
         swapRouter =  ISwapRouter(contractSwap);
         WETH9 = IERC20(contractWeth9);
     }
    
      function exactInput(uint256 amountIn, address tokenIn, address tokenOut) external returns(uint[] memory amount){

            require(IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn),"transferFrom failed");
            require( IERC20(tokenIn).approve(address(swapRouter), amountIn), "approve failed");

            address[] memory path = new address[](2);
            path[0]= tokenIn;
          //   path[1] = address(WETH9);
            path[1]= tokenOut;

            amount = swapRouter.swapExactTokensForTokens(amountIn, 0, path, msg.sender, block.timestamp);


      }

}