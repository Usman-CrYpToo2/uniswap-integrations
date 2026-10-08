// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Swappingv3_MultiHop.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Test_swappingv3_multiHop is Test {
    IERC20 public constant WETH9 = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);  
    Swappingv3_MultiHop public swappingv3;

    function setUp() public {
         swappingv3 = new Swappingv3_MultiHop();
    }

    function test_multiHopSwapWethForDaiExactInput() public {
         uint256 amountIn = 5 ether;
            (bool success,) = address(WETH9).call{value : amountIn}("");
            require(success, "Transfer failed");
            console.log("WEth balance :: ", WETH9.balanceOf(address(this)));
            console.log("DAI balance :: ", DAI.balanceOf(address(this)));
            WETH9.approve(address(swappingv3), amountIn);
            uint256 _amountOut = swappingv3.multiHopSwapWethForDaiExactInput(amountIn);
            console.log("DAI balance after swap :: ", DAI.balanceOf(address(this))  / 1e18 );
            console.log("DAI amount received :: ", _amountOut / 1e18 ) ;    
            assertEq(_amountOut, DAI.balanceOf(address(this)));
    }

    function test_multiHopSwapWethForDaiExactOutput() public {
        uint256 _amountIn = 10 ether;
        vm.deal(address(this), _amountIn);
        (bool success, ) = address(WETH9).call{value : _amountIn}("");
        require(success, "transaction failed");
        console.log("WEth balance :: ", WETH9.balanceOf(address(this)));
        console.log("Dai balance :: ", DAI.balanceOf(address(this)));
        WETH9.approve(address(swappingv3), _amountIn);
        uint256 amountIn = swappingv3.multiHopSwapWethForDaiExactOutput(1000e18, _amountIn);
        console.log("amount weth used :: ", amountIn );
        console.log("Dai balance :: ", DAI.balanceOf(address(this)));
        assertEq(1000e18, DAI.balanceOf(address(this)));
    }
}