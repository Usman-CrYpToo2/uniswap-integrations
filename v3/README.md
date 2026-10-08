# Uniswap V3 Integrations

[![v3](https://github.com/Usman-CrYpToo2/uniswap-integrations/actions/workflows/v3.yml/badge.svg)](https://github.com/Usman-CrYpToo2/uniswap-integrations/actions/workflows/v3.yml)

Foundry project integrating with the Uniswap V3 mainnet deployment: single-hop and multi-hop swaps, and concentrated liquidity positions managed through the `NonfungiblePositionManager`.

> [!WARNING]
> Educational code. Unaudited and not intended for deployment.

## Contracts

| Contract | Description |
|---|---|
| [`Swappingv3_SingleHop`](src/Swappingv3_SingleHop.sol) | WETH to DAI through the 0.3% pool, exact-input and exact-output |
| [`Swappingv3_MultiHop`](src/Swappingv3_MultiHop.sol) | WETH to DAI routed through an intermediate stablecoin, exact-input and exact-output |
| [`addingLiquidity`](src/addingLiquidity.sol) | Custodies `NonfungiblePositionManager` positions: mint, increase, decrease, collect fees, retrieve |

Dependencies: `SwapRouter` at `0xE592427A0AEce92De3Edee1F18E0157C05861564`, `NonfungiblePositionManager` at `0xC36442b4a4522E871399CD717aBDD847Ab11FE88`.

## Design Notes

**Path encoding.** Multi-hop routes are packed as `tokenIn, fee, tokenMid, fee, tokenOut` (20 + 3 + 20 + 3 + 20 bytes). For exact-output swaps the router walks the path backwards, so the path is encoded from `tokenOut` to `tokenIn`.

**Exact-output refunds.** An exact-output swap pulls the caller's maximum input up front and spends only what the route requires. The difference is refunded to the caller, and the router allowance is reset to zero.

**Position custody.** Positions are ERC-721 tokens. The manager records each position's owner and liquidity in `deposits`. Fees and withdrawn liquidity are always sent to the recorded owner, and the owner can reclaim the NFT with `retrieveNFT`.

## Usage

Requires [Foundry](https://book.getfoundry.sh/getting-started/installation) and an archive RPC endpoint, since tests fork mainnet at block 21,000,000.

```bash
git clone --recurse-submodules https://github.com/Usman-CrYpToo2/uniswap-integrations.git
cd uniswap-integrations/v3
export MAINNET_RPC_URL=<archive-rpc-url>
forge test
```

The suite contains 11 fork tests, including a regression test for each resolved finding. CI builds the project on every push and runs the fork tests when a `MAINNET_RPC_URL` repository secret is configured.

## Security Review

Resolved in [`d78566f`](https://github.com/Usman-CrYpToo2/uniswap-integrations/commit/d78566f). The pre-fix sources are preserved in [`0be54b3`](https://github.com/Usman-CrYpToo2/uniswap-integrations/commit/0be54b3).

| ID | Severity | Title | Status |
|---|---|---|---|
| V3-C-01 | Critical | Unauthenticated `onERC721Received` allows takeover of any deposit | Fixed |
| V3-H-01 | High | Exact-output refunds always revert | Fixed |
| V3-H-02 | High | Single-hop `WETH9` constant holds the USDC address | Fixed |
| V3-M-01 | Medium | Recorded liquidity not updated after increases | Fixed |
| V3-M-02 | Medium | Position NFTs cannot be retrieved | Fixed |
| V3-M-03 | Medium | No slippage protection | Acknowledged |
| V3-L-01 | Low | Deadline set to `block.timestamp + 1000` | Acknowledged |
| V3-I-01 | Info | Fixed position amounts and full-range ticks | Acknowledged |

**V3-C-01.** `onERC721Received` passed the caller-supplied `operator` to `_createDeposit` without checking `msg.sender`. Anyone could call it directly with another user's `tokenId`, overwrite the recorded owner, and drain the position through repeated `decreaseLiquidityInHalf` calls. The same pattern appears in the Uniswap documentation example this contract is based on. *Fix:* require `msg.sender == nonfungiblePositionManager`.

**V3-H-01.** Both swap contracts refunded unused input with `safeTransferFrom(token, address(this), msg.sender, amount)`. A contract has no allowance over its own balance, so every exact-output swap that did not consume the full maximum reverted. *Fix:* `safeTransfer`.

**V3-H-02.** The constant named `WETH9` was set to `0xA0b8...eB48`, the USDC address, with the 0.01% fee tier. The "WETH to DAI" swaps actually pulled USDC from the caller. *Fix:* the WETH address and the 0.3% WETH/DAI pool.

**V3-M-01.** `increaseLiquidityCurrentRange` did not update `deposits[tokenId].liquidity`, so `decreaseLiquidityInHalf` operated on the size at mint time. *Fix:* track liquidity on both increase and decrease.

**V3-M-02.** Positions transferred to the manager could never leave it; owners could only withdraw liquidity in halves. *Fix:* owner-only `retrieveNFT`, with the record cleared before the external call.

**V3-M-03.** All swaps and liquidity operations pass zero minimums, leaving them exposed to sandwiching. *Recommendation:* caller-supplied `amountOutMinimum` and `amount0Min`/`amount1Min`.

**V3-L-01.** A deadline derived from `block.timestamp` is evaluated at execution time and provides no protection against delayed inclusion. *Recommendation:* caller-supplied deadline.

**V3-I-01.** `mintNewPosition` uses hardcoded amounts and the full tick range. Suitable for a stable pair example, not for general use.

## Acknowledgements

The contracts are adapted from the examples in the [Uniswap V3 developer guides](https://docs.uniswap.org/contracts/v3/guides/). The fixes, tests, and security review are original.
