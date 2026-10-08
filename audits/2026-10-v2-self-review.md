# Self-Review: Uniswap V2 Integrations

| | |
|---|---|
| Date | October 2026 |
| Commit reviewed | [`3244038`](https://github.com/Usman-CrYpToo2/uniswap-integrations/commit/3244038) |
| Scope | All contracts under [`v2/`](../v2) |
| Method | Manual review |

This is a self-review, not an independent audit. Findings are acknowledged and left unfixed; the V2 modules are retained as a reference.

## Summary

| Severity | Count |
|---|---|
| Critical | 1 |
| High | 2 |
| Medium | 1 |
| Low | 2 |
| Informational | 1 |

## Findings

| ID | Severity | Title | Location |
|---|---|---|---|
| V2-C-01 | Critical | Any caller can withdraw all pooled liquidity | `v2/add-liquidity/contracts/AddLiquidity.sol` |
| V2-H-01 | High | No slippage protection on swaps or liquidity operations | All modules |
| V2-H-02 | High | Deadline set to `block.timestamp` is always satisfied | All modules |
| V2-M-01 | Medium | `optimalAmount` ignores token ordering | `v2/optimal-swap-liquidity/contracts/optimalSwap.sol` |
| V2-L-01 | Low | Pair existence not checked before reading reserves | `v2/optimal-swap-liquidity/contracts/optimalSwap.sol` |
| V2-L-02 | Low | Unchecked ERC-20 return values | All modules |
| V2-I-01 | Info | Flash swap fee requires the contract to be pre-funded | `v2/flash-swap/contracts/FlashSwap.sol` |

**V2-C-01.** `Liquidity` holds LP tokens for every depositor in a single balance. `LiquidityRemove` burns the contract's entire LP balance and pays the underlying tokens to the caller. *Recommendation:* track LP shares per depositor, or mint LP tokens directly to the user.

**V2-H-01.** Swaps pass `amountOutMin` of `0` or `1`, and `addLiquidity` and `removeLiquidity` pass minimums of `0` or `1`. Transactions are fully exposed to sandwiching. *Recommendation:* accept caller-supplied minimums.

**V2-H-02.** Every router call uses `block.timestamp` as the deadline, which passes at any execution time. *Recommendation:* accept a caller-supplied deadline.

**V2-M-01.** `optimalAmount` always reads the second reserve. When token A is `token0`, the result is computed against the wrong reserve. `swap` handles ordering correctly. *Recommendation:* select the reserve by comparing against `token0()`.

**V2-L-01.** `optimalSwap.swap` calls `getReserves` on the result of `getPair` without checking for `address(0)`. *Recommendation:* revert when the pair does not exist.

**V2-L-02.** Return values of `transfer` and `transferFrom` are ignored in most paths. *Recommendation:* use `SafeERC20`.

**V2-I-01.** The callback pays the fee from the contract's own balance, so it reverts unless the contract is funded beforehand.
