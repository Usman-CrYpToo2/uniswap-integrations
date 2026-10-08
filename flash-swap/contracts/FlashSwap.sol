// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IFactoryV2.sol";
import "./interfaces/IPairV2.sol";
import "./interfaces/IFlashSwapV2.sol";

contract flashSwap is IFlashSwap{

      address constant v2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
     
      event log(string indexed message, uint indexed value);
      function testFlashSwap(address token0, address token1, uint amount0) external{
            address pair = Ifactory(v2Factory).getPair(token0, token1);

            require(pair != address(0), "first create the pair");

            address token0address = IPair(pair).token0();
            address token1address = IPair(pair).token1();

            uint amount0Out = token0address == token0 ? amount0 : 0;
            uint amount1Out = token1address == token0 ? amount0 : 0;
            
             bytes memory data = abi.encode(token0, amount0);
            IPair(pair).swap(amount0Out, amount1Out, address(this), data);
      }

      function uniswapV2Call(address sender,uint amount1,uint amount2,bytes memory data) override external{
           address token0 = IPair(msg.sender).token0();
           address token1 = IPair(msg.sender).token1();

           address pair = Ifactory(v2Factory).getPair(token0, token1);

           require(msg.sender == pair, "caller must be the pair Contract");

           require(sender == address(this),"sender is this address");

           (address borrowedToken, uint amount0) = abi.decode(data, (address, uint));

           uint fee = ((amount0 * 3) / 997) + 1;
           
           uint amountToRepay = amount0 + fee;
           
            uint wethAmount = IERC20(borrowedToken).balanceOf(address(this));
          
           
            emit log("balance of weth before paying the borrowedToken :: ", wethAmount);
            emit log("amount1 :: ",amount1);
            emit log("amount2 :: ",amount2);
            emit log("fee",fee);
            emit log("amount to repay :: ", amountToRepay );
           IERC20(borrowedToken).transfer(pair, amountToRepay);

      } 
      
}