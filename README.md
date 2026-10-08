# Uniswap Integrations

[![v3](https://github.com/Usman-CrYpToo2/uniswap-integrations/actions/workflows/v3.yml/badge.svg)](https://github.com/Usman-CrYpToo2/uniswap-integrations/actions/workflows/v3.yml)

Reference integrations against the Uniswap V2 and V3 mainnet deployments, each with a structured security review. V2 covers swaps, liquidity provision, an optimal single-sided zap, and flash swaps. V3 covers single-hop and multi-hop swaps and concentrated liquidity positions managed through the `NonfungiblePositionManager`.

> [!WARNING]
> Educational code. Unaudited and not intended for deployment. Findings are documented under each section's security review.

## Repository Structure

| Path | Toolchain | Contents |
|---|---|---|
| [`v2/`](v2) | Hardhat | Four standalone modules: swap, add liquidity, optimal swap, flash swap |
| [`v3/`](v3) | Foundry, solc 0.7.6 | Single-hop and multi-hop swaps, liquidity position manager, fork tests |

---

## Uniswap V2

| Module | Contract | Description |
|---|---|---|
| [`swap`](v2/swap) | `Swapping` | Exact-input swap through `UniswapV2Router02.swapExactTokensForTokens`. |
| [`add-liquidity`](v2/add-liquidity) | `Liquidity` | Adds and removes liquidity via the router, refunding unused token amounts. |
| [`optimal-swap-liquidity`](v2/optimal-swap-liquidity) | `optimalSwap` | Computes the swap amount that leaves a single-asset balance in pool ratio, then adds liquidity. |
| [`flash-swap`](v2/flash-swap) | `flashSwap` | Borrows from a pair via `swap` with callback data and repays within `uniswapV2Call`. |

Dependencies: `UniswapV2Router02` at `0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D`, `UniswapV2Factory` at `0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f`.

### Design Notes

**Optimal swap amount.** Adding liquidity from a single asset requires swapping part of it first. Swapping half leaves a residual balance, because the swap moves the price and pays the 0.3% fee. Given reserve `r` of token A and balance `a`, the amount `s` that leaves both sides in pool ratio is:

```
s = (sqrt(r * (3988009 * r + 3988000 * a)) - 1997 * r) / 1994
```

The constants follow from the constant product invariant with a fee factor of 997/1000. The square root uses the Babylonian method ([`Library.sol`](v2/optimal-swap-liquidity/contracts/Interfaces/Library.sol)).

**Flash swap repayment.** `testFlashSwap` calls `pair.swap` with non-empty `data`, so the pair transfers first and then calls `uniswapV2Call`. The callback validates that `msg.sender` is the factory-registered pair and that `sender` is this contract, computes the fee as `amount * 3 / 997 + 1`, and repays `amount + fee`. An insufficient repayment fails the pair's `k` check and reverts.

### Usage

```bash
cd v2/swap   # or any module
npm install
export MAINNET_RPC_URL=<rpc-url>

npx hardhat node                                          # terminal 1: mainnet fork
npx hardhat run scripts/deploy.js --network localhost     # terminal 2
npx hardhat test --network localhost
```

Tests resolve the contract at the fixed `contractAddress` declared in each test file. They are scripted walkthroughs that log balances and events and do not assert results.

### Security Review

Findings are acknowledged and left unfixed; the V2 modules are retained as a reference.

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

---

## Uniswap V3

| Contract | Description |
|---|---|
| [`Swappingv3_SingleHop`](v3/src/Swappingv3_SingleHop.sol) | WETH to DAI through the 0.3% pool, exact-input and exact-output |
| [`Swappingv3_MultiHop`](v3/src/Swappingv3_MultiHop.sol) | WETH to DAI routed through an intermediate stablecoin, exact-input and exact-output |
| [`addingLiquidity`](v3/src/addingLiquidity.sol) | Custodies `NonfungiblePositionManager` positions: mint, increase, decrease, collect fees, retrieve |

Dependencies: `SwapRouter` at `0xE592427A0AEce92De3Edee1F18E0157C05861564`, `NonfungiblePositionManager` at `0xC36442b4a4522E871399CD717aBDD847Ab11FE88`.

### Design Notes

**Path encoding.** Multi-hop routes are packed as `tokenIn, fee, tokenMid, fee, tokenOut` (20 + 3 + 20 + 3 + 20 bytes). For exact-output swaps the router walks the path backwards, so the path is encoded from `tokenOut` to `tokenIn`.

**Exact-output refunds.** An exact-output swap pulls the caller's maximum input up front and spends only what the route requires. The difference is refunded to the caller, and the router allowance is reset to zero.

**Position custody.** Positions are ERC-721 tokens. The manager records each position's owner and liquidity in `deposits`. Fees and withdrawn liquidity are always sent to the recorded owner, and the owner can reclaim the NFT with `retrieveNFT`.

### Usage

Requires [Foundry](https://book.getfoundry.sh/getting-started/installation) and an archive RPC endpoint, since tests fork mainnet at block 21,000,000.

```bash
git clone --recurse-submodules https://github.com/Usman-CrYpToo2/uniswap-integrations.git
cd uniswap-integrations/v3
export MAINNET_RPC_URL=<archive-rpc-url>
forge test
```

The suite contains 11 fork tests, including a regression test for each resolved finding. CI builds the project on every push and runs the fork tests when a `MAINNET_RPC_URL` repository secret is configured.

### Security Review

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

---

## Acknowledgements

The V3 contracts are adapted from the examples in the [Uniswap V3 developer guides](https://docs.uniswap.org/contracts/v3/guides/). The fixes, tests, and security review are original.

## License

GPL-3.0, see [`LICENSE`](LICENSE). Files marked MIT in their SPDX header remain MIT.
