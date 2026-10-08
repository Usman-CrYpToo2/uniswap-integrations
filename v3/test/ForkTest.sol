// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";

/// Forks mainnet at a fixed block so results are deterministic and RPC responses are cached.
/// Requires MAINNET_RPC_URL pointing to an archive node.
abstract contract ForkTest is Test {
    uint256 internal constant FORK_BLOCK = 21_000_000;

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function _fork() internal {
        vm.createSelectFork("mainnet", FORK_BLOCK);
    }
}
