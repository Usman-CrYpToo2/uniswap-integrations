// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0;

import "./Interfaces/IERC20.sol";
import "./Interfaces/Ifactory.sol";
import "./Interfaces/IPair.sol";
import "./Interfaces/Library.sol";
import "./Interfaces/uniswapV2Router.sol";


contract optimalSwap{
        address constant v2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

     address constant v2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
      
    function swap (address tokenA, address tokenB, uint256 amountA) external returns(uint[] memory amount){
         
        
         address pair = Ifactory(v2Factory).getPair(tokenA, tokenB);
         
         (uint reserve1, uint reserve2,) = IPair(pair).getReserves();
          
          uint swapAmountA ;
          if(IPair(pair).token0() == tokenA){
                swapAmountA = optimal.getSwapAmount(reserve1, amountA);
          }
          else {
                swapAmountA = optimal.getSwapAmount(reserve2, amountA);
          }
            
           address[] memory path = new address[](2);

          path[0] = tokenA;
          path[1] = tokenB;

          IERC20(tokenA).transferFrom(msg.sender, address(this), swapAmountA);
          IERC20(tokenA).approve(v2Router, swapAmountA);
          amount = ISwapRouter(v2Router).swapExactTokensForTokens(swapAmountA, 1, path, msg.sender, block.timestamp);

    } 

     function LiquidityAdd(address tokenA, address tokenB, uint amountInA, uint amountInB) external returns(uint AmountA,uint AmountB, uint liquidity){
            IERC20(tokenA).transferFrom(msg.sender, address(this), amountInA);
            IERC20(tokenB).transferFrom(msg.sender, address(this), amountInB);

            IERC20(tokenA).approve(v2Router, amountInA);
            IERC20(tokenB).approve(v2Router, amountInB);

             (AmountA, AmountB, liquidity)=ISwapRouter(v2Router).addLiquidity(tokenA, tokenB, amountInA, amountInB, 1, 1, msg.sender, block.timestamp);
     }

     function optimalAmount(address tokenA, address tokenB, uint amountA) external view returns(uint){
            
         address pair = Ifactory(v2Factory).getPair(tokenA, tokenB);

         (uint reserve1, uint reserve2,) = IPair(pair).getReserves();
         
          uint swapAmount = optimal.getSwapAmount(reserve2, amountA);
          return swapAmount;
     }
       
}