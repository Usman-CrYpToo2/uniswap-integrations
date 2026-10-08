// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0;

library optimal {
     
    function sqrt(uint256 y ) internal pure returns(uint256 z){
        if(y > 3){
           z = y;
           uint256 x = y / 2 + 1;

           while ( x < z) {
                z = x;
                x = (y / x + x) / 2;
           }
    }
      else if( y != 0) { 
          z = 1;
      }
    }

    function getSwapAmount(uint a, uint r) internal pure returns(uint){
        uint256 inner = a * ((r * 3988000) + (a * 3988009)) ;
        uint256 inSqrt = sqrt(inner) - (a * 1997);
        return (inSqrt / 1994);
    }
}