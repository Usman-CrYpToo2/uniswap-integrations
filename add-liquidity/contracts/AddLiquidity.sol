// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.7.0;

import "./Interface/IERC20.sol";
import "./Interface/IFactoryV2.sol";
import "./Interface/IUniswapV2Router.sol";


contract Liquidity{
    
    address constant factoryV2 = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant RouterV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    event LiquidityData(string indexed message, uint256 indexed amount);

    function LiquidityAdd(address tokenA, address tokenB, uint amountA, uint amountB) external  returns(uint amount0, uint amount1, uint liquidity){
           IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
           IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

           IERC20(tokenA).approve(RouterV2, amountA);
           IERC20(tokenB).approve(RouterV2, amountB);

         (amount0, amount1, liquidity) = IswapRouterV2(RouterV2).addLiquidity(tokenA, tokenB, amountA, amountB, 0, 0, address(this), block.timestamp);
            
         emit LiquidityData("token0 amount in liquidity :: ", amount0);
         emit LiquidityData("token1 amount in Liquidity :: ", amount1);
         emit LiquidityData("lp-token give to the user", liquidity);

         if(amount0 < amountA){
               IERC20(tokenA).transfer(msg.sender, amountA - amount0);
         }

         if(amount1 < amountB){
             IERC20(tokenB).transfer(msg.sender, amountB - amount1);
         }

    }

    function LiquidityRemove(address tokenA, address tokenB) external returns(uint amountA, uint amountB){
         
          address pair = Ifactory(factoryV2).getPair(tokenA, tokenB);

          uint userLiquidity = IERC20(pair).balanceOf(address(this));

          IERC20(pair).approve(RouterV2, userLiquidity);  
          (amountA, amountB)= IswapRouterV2(RouterV2).removeLiquidity(tokenA, tokenB, userLiquidity, 0, 0, address(this), block.timestamp);
          
          emit LiquidityData("the amountA return to lp", amountA);
          emit LiquidityData("the amountB return to lp", amountB);
          
          IERC20(tokenA).transfer(msg.sender, amountA);
          IERC20(tokenB).transfer(msg.sender, amountB);
    }
    
}