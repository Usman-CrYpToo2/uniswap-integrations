// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {INonfungiblePositionManager} from "v3-periphery/interfaces/INonfungiblePositionManager.sol";
import {ForkTest} from "./ForkTest.sol";
import {addingLiquidity} from "../src/addingLiquidity.sol";

contract LiquidityTest is ForkTest, IERC721Receiver {
    INonfungiblePositionManager constant NPM = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    addingLiquidity manager;
    address attacker = makeAddr("attacker");
    uint256 tokenId;

    function setUp() public {
        _fork();
        manager = new addingLiquidity();
        deal(DAI, address(this), 200_000e18);
        deal(USDC, address(this), 200_000e6);
        IERC20(DAI).approve(address(manager), type(uint256).max);
        IERC20(USDC).approve(address(manager), type(uint256).max);
        (tokenId,,,) = manager.mintNewPosition();
    }

    /// Lets this test contract receive the position NFT in test_retrieveNFT.
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function _recordedLiquidity() internal view returns (uint128 liquidity) {
        (, liquidity,,) = manager.deposits(tokenId);
    }

    function test_mint_recordsDeposit() public view {
        (address owner, uint128 liquidity, address token0, address token1) = manager.deposits(tokenId);
        assertEq(owner, address(this));
        assertGt(uint256(liquidity), 0);
        assertEq(token0, DAI);
        assertEq(token1, USDC);
        assertEq(NPM.ownerOf(tokenId), address(manager));
    }

    /// Regression for C-01: a direct call must not be able to take over a deposit.
    function test_onERC721Received_rejectsDirectCall() public {
        vm.prank(attacker);
        vm.expectRevert("not position manager");
        manager.onERC721Received(attacker, address(0), tokenId, "");
    }

    /// Regression for M-01: the recorded liquidity must follow increases.
    function test_increaseLiquidity_updatesRecord() public {
        uint128 before = _recordedLiquidity();
        (uint128 added,,) = manager.increaseLiquidityCurrentRange(tokenId, 1_000e18, 1_000e6);
        assertGt(uint256(added), 0);
        assertEq(uint256(_recordedLiquidity()), uint256(before) + added);
    }

    function test_decreaseLiquidityInHalf_paysOwner() public {
        uint128 before = _recordedLiquidity();
        uint256 daiBefore = IERC20(DAI).balanceOf(address(this));
        uint256 usdcBefore = IERC20(USDC).balanceOf(address(this));

        manager.decreaseLiquidityInHalf(tokenId);

        assertGt(IERC20(DAI).balanceOf(address(this)), daiBefore);
        assertGt(IERC20(USDC).balanceOf(address(this)), usdcBefore);
        assertEq(uint256(_recordedLiquidity()), uint256(before - before / 2));
    }

    function test_decreaseLiquidity_onlyOwner() public {
        vm.prank(attacker);
        vm.expectRevert("only owner can decrease liquidity");
        manager.decreaseLiquidityInHalf(tokenId);
    }

    /// Regression for M-02: the owner can take the position NFT back.
    function test_retrieveNFT() public {
        manager.retrieveNFT(tokenId);
        assertEq(NPM.ownerOf(tokenId), address(this));
        (address owner,,,) = manager.deposits(tokenId);
        assertEq(owner, address(0));
    }

    function test_retrieveNFT_onlyOwner() public {
        vm.prank(attacker);
        vm.expectRevert("not owner");
        manager.retrieveNFT(tokenId);
    }
}
