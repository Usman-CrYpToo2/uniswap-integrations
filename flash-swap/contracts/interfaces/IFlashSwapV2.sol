// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0;

interface IFlashSwap {
        
        function uniswapV2Call(address sender, uint amount1, uint amount2, bytes calldata data) external;
    
}