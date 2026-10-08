// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ForkTest} from "./ForkTest.sol";
import {Swappingv3_SingleHop} from "../src/Swappingv3_SingleHop.sol";
import {Swappingv3_MultiHop} from "../src/Swappingv3_MultiHop.sol";

contract SwapsTest is ForkTest {
    Swappingv3_SingleHop single;
    Swappingv3_MultiHop multi;

    function setUp() public {
        _fork();
        single = new Swappingv3_SingleHop();
        multi = new Swappingv3_MultiHop();
    }

    function _fundWeth(address spender, uint256 amount) internal {
        deal(WETH, address(this), amount);
        IERC20(WETH).approve(spender, amount);
    }

    function test_singleHop_exactInput() public {
        _fundWeth(address(single), 5 ether);
        uint256 out = single.singleHopSwapWethForDaiExactInput(5 ether);
        assertGt(out, 0);
        assertEq(IERC20(DAI).balanceOf(address(this)), out);
        assertEq(IERC20(WETH).balanceOf(address(this)), 0);
    }

    /// Regression for H-01: the unused input must come back to the caller.
    function test_singleHop_exactOutput_refundsUnusedInput() public {
        _fundWeth(address(single), 5 ether);
        uint256 spent = single.singleHopSwapWethForDaiExactOutput(1_000e18, 5 ether);
        assertEq(IERC20(DAI).balanceOf(address(this)), 1_000e18);
        assertEq(IERC20(WETH).balanceOf(address(this)), 5 ether - spent);
        assertEq(IERC20(WETH).balanceOf(address(single)), 0);
    }

    function test_multiHop_exactInput() public {
        _fundWeth(address(multi), 5 ether);
        uint256 out = multi.multiHopSwapWethForDaiExactInput(5 ether);
        assertGt(out, 0);
        assertEq(IERC20(DAI).balanceOf(address(this)), out);
    }

    /// Regression for H-01 on the multi-hop path.
    function test_multiHop_exactOutput_refundsUnusedInput() public {
        _fundWeth(address(multi), 10 ether);
        uint256 spent = multi.multiHopSwapWethForDaiExactOutput(1_000e18, 10 ether);
        assertEq(IERC20(DAI).balanceOf(address(this)), 1_000e18);
        assertEq(IERC20(WETH).balanceOf(address(this)), 10 ether - spent);
        assertEq(IERC20(WETH).balanceOf(address(multi)), 0);
    }
}
