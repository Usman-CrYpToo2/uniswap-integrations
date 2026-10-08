# Self-Review: Uniswap V3 Integrations

| | |
|---|---|
| Date | October 2026 |
| Commit reviewed | [`0be54b3`](https://github.com/Usman-CrYpToo2/uniswap-integrations/commit/0be54b3) |
| Fixes | [`d78566f`](https://github.com/Usman-CrYpToo2/uniswap-integrations/commit/d78566f) |
| Scope | All contracts under [`v3/src`](../v3/src) |
| Method | Manual review; a mainnet fork regression test was written for each fix |

This is a self-review, not an independent audit.

## Summary

| Severity | Count | Fixed | Acknowledged |
|---|---|---|---|
| Critical | 1 | 1 | 0 |
| High | 2 | 2 | 0 |
| Medium | 3 | 2 | 1 |
| Low | 1 | 0 | 1 |
| Informational | 1 | 0 | 1 |

Each fix has a regression test.

## Findings

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
