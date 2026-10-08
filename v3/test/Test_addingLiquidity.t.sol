// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/addingLiquidity.sol";
import "v3-periphery/interfaces/INonfungiblePositionManager.sol";
import "../src/Swappingv3_SingleHop.sol";


contract Test_addingLiquidity is Test {
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant DAI_WHALE = 0xD1668fB5F690C59Ab4B0CAbAd0f8C1617895052B;
    address public constant USDC_WHALE = 0x7713974908Be4BEd47172370115e8b1219F4A5f0;
        INonfungiblePositionManager public constant nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
     uint256 public tokenIDs;
     addingLiquidity public addingLiquidityContract;
     Swappingv3_SingleHop public swappingv3_SingleHopContract;

    function setUp() public {
        addingLiquidityContract = new addingLiquidity(); 
        swappingv3_SingleHopContract = new Swappingv3_SingleHop();
    }
    
     function test_mintNewPosition() public {
        vm.prank(USDC_WHALE);
        IERC20(USDC).transfer(address(this), 100000e6);
        vm.prank(DAI_WHALE);
        IERC20(DAI).transfer(address(this), 100000e18);

        console.log("DAI balance: ", IERC20(DAI).balanceOf(address(this)));
        console.log("USDC balance: ", IERC20(USDC).balanceOf(address(this)));

        IERC20(DAI).approve(address(addingLiquidityContract), 100000e18);
        IERC20(USDC).approve(address(addingLiquidityContract), 100000e6);

        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = addingLiquidityContract.mintNewPosition();
        console.log("tokenId: ", tokenId);
        console.log("liquidity: ", liquidity);
        console.log("amount0: ", amount0);
        console.log("amount1: ", amount1);
        tokenIDs = tokenId;

        //  (address owner, , , ) = addingLiquidityContract.deposits(tokenId);
        //  console.log(owner);
        //  console.log(address(this));
        //  console.log(address(addingLiquidityContract));
        //  uint256 this_balance = nonfungiblePositionManager.balanceOf(address(this));
        //  console.log("address(this) :: ", this_balance);
        //  uint256 owner_balance = nonfungiblePositionManager.balanceOf(address(addingLiquidityContract));
        //     console.log("address(addingLiquidityContract) :: ", owner_balance);
     }

     function test_collectAllfee() public {
          test_mintNewPosition();
        // vm.prank(USDC_WHALE);
        // IERC20(USDC).transfer(address(this), 100000e6);
       for(uint i= 0; i < 10 ; i++) {
         vm.prank(USDC_WHALE);
        IERC20(USDC).transfer(address(this), 100000e6);
        console.log("DAI balance: ", IERC20(DAI).balanceOf(address(this)));
        IERC20(USDC).approve(address(swappingv3_SingleHopContract), 100000e6);
        swappingv3_SingleHopContract.singleHopSwapWethForDaiExactInput(100000e6);
         console.log( "balance in dai" , IERC20(DAI).balanceOf(address(this)));
       }
         (uint256 amount0fee, uint256 amount1fee) = addingLiquidityContract.collectingAllFee(tokenIDs);
            console.log("amount0fee: ", amount0fee);
            console.log("amount1fee: ", amount1fee);
            console.log("usdc balance: ", IERC20(USDC).balanceOf(address(this)));

     }

     function test_inscreaseLiquidity() public {
        test_mintNewPosition();
           vm.prank(USDC_WHALE);
        IERC20(USDC).transfer(address(this), 100000e6);
        vm.prank(DAI_WHALE);
        IERC20(DAI).transfer(address(this), 100000e18);
        console.log("DAI balance: ", IERC20(DAI).balanceOf(address(this)));
        console.log("USDC balance: ", IERC20(USDC).balanceOf(address(this)));
        IERC20(DAI).approve(address(addingLiquidityContract), 100000e18);
        IERC20(USDC).approve(address(addingLiquidityContract), 100000e6);
        (uint128 liquidity, uint256 amount0, uint256 amount1) = addingLiquidityContract.increaseLiquidityCurrentRange(tokenIDs, 100000e18, 100000e6);
         
        console.log("liquidity: ", liquidity);
        console.log("amount0: ", amount0);
        console.log("amount1: ", amount1);

     }
   
     function test_decreaseLiquidity() public {
        test_mintNewPosition();
        (uint256 amount0, uint256 amount1) = addingLiquidityContract.decreaseLiquidityInHalf(tokenIDs);
        console.log("amount0: ", amount0);
        console.log("amount1: ", amount1);
     }
     
    
}