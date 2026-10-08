// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.7.0;

interface IPair{

         function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

         function token0() external view returns (address);

         function token1() external view returns (address);
         

}