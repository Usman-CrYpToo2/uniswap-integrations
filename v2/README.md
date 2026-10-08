# Uniswap V2 Integrations

Hardhat modules integrating with the Uniswap V2 mainnet deployment: exact-input swaps, liquidity provision, an optimal single-sided zap, and flash swaps.

## Modules

| Module | Contract | Description |
|---|---|---|
| [`swap`](swap) | `Swapping` | Exact-input swap through `UniswapV2Router02.swapExactTokensForTokens`. |
| [`add-liquidity`](add-liquidity) | `Liquidity` | Adds and removes liquidity via the router, refunding unused token amounts. |
| [`optimal-swap-liquidity`](optimal-swap-liquidity) | `optimalSwap` | Computes the swap amount that leaves a single-asset balance in pool ratio, then adds liquidity. |
| [`flash-swap`](flash-swap) | `flashSwap` | Borrows from a pair via `swap` with callback data and repays within `uniswapV2Call`. |

Dependencies: `UniswapV2Router02` at `0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D`, `UniswapV2Factory` at `0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f`.

## Design Notes

**Optimal swap amount.** Adding liquidity from a single asset requires swapping part of it first. Swapping half leaves a residual balance, because the swap moves the price and pays the 0.3% fee. Given reserve `r` of token A and balance `a`, the amount `s` that leaves both sides in pool ratio is:

```
s = (sqrt(r * (3988009 * r + 3988000 * a)) - 1997 * r) / 1994
```

The constants follow from the constant product invariant with a fee factor of 997/1000. The square root uses the Babylonian method ([`Library.sol`](optimal-swap-liquidity/contracts/Interfaces/Library.sol)).

**Flash swap repayment.** `testFlashSwap` calls `pair.swap` with non-empty `data`, so the pair transfers first and then calls `uniswapV2Call`. The callback validates that `msg.sender` is the factory-registered pair and that `sender` is this contract, computes the fee as `amount * 3 / 997 + 1`, and repays `amount + fee`. An insufficient repayment fails the pair's `k` check and reverts.

## Usage

```bash
cd v2/swap   # from the repository root; any module works the same way
npm install
export MAINNET_RPC_URL=<rpc-url>

npx hardhat node                                          # terminal 1: mainnet fork
npx hardhat run scripts/deploy.js --network localhost     # terminal 2
npx hardhat test --network localhost
```

Tests resolve the contract at the fixed `contractAddress` declared in each test file. They are scripted walkthroughs that log balances and events and do not assert results.

## Security

A self-review found 7 issues, including one critical. They are acknowledged and left unfixed, as the modules are kept as a reference. See [`audits/2026-10-v2-self-review.md`](../audits/2026-10-v2-self-review.md).
