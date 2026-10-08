// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0;

interface Ifactory{
      
      function getPair(address tokenA, address tokenB) external view returns (address pair);

}