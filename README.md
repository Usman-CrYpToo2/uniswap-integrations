# Uniswap V2 Integrations

Reference integrations against the Uniswap V2 mainnet deployment: exact-input swaps, liquidity provision, an optimal single-sided zap, and flash swaps. Each module is a self-contained Hardhat project tested against a mainnet fork.

> [!WARNING]
> Educational code. Unaudited, with known vulnerabilities documented under [Security](#security). Not intended for deployment.

## Modules

| Module | Contract | Description |
|---|---|---|
| [`swap`](swap) | `Swapping` | Exact-input swap through `UniswapV2Router02.swapExactTokensForTokens`. |
| [`add-liquidity`](add-liquidity) | `Liquidity` | Adds and removes liquidity via the router, refunding unused token amounts. |
| [`optimal-swap-liquidity`](optimal-swap-liquidity) | `optimalSwap` | Computes the swap amount that leaves a single-asset balance in pool ratio, then adds liquidity. |
| [`flash-swap`](flash-swap) | `flashSwap` | Borrows from a pair via `swap` with callback data and repays within `uniswapV2Call`. |

External dependencies are the canonical mainnet deployments:

| Contract | Address |
|---|---|
| `UniswapV2Router02` | `0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D` |
| `UniswapV2Factory` | `0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f` |

## Design Notes

### Optimal swap amount

Adding liquidity from a single asset requires swapping part of it first. Swapping half leaves a residual balance, because the swap moves the price and pays the 0.3% fee. Given reserve `r` of token A and balance `a`, the amount `s` that leaves both sides in pool ratio is:

```
s = (sqrt(r * (3988009 * r + 3988000 * a)) - 1997 * r) / 1994
```

The constants follow from the constant product invariant with a fee factor of 997/1000. The square root uses the Babylonian method ([`Library.sol`](optimal-swap-liquidity/contracts/Interfaces/Library.sol)).

### Flash swap repayment

`testFlashSwap` calls `pair.swap` with non-empty `data`, so the pair transfers first and then calls `uniswapV2Call`. The callback:

1. Validates that `msg.sender` is the factory-registered pair and that `sender` is this contract.
2. Computes the fee as `amount * 3 / 997 + 1`.
3. Transfers `amount + fee` back to the pair. An insufficient repayment fails the pair's `k` check and reverts the transaction.

## Usage

Requires Node.js and a mainnet RPC endpoint.

```bash
cd swap   # or any module
npm install
export MAINNET_RPC_URL=<rpc-url>

npx hardhat node                                          # terminal 1: mainnet fork
npx hardhat run scripts/deploy.js --network localhost     # terminal 2
npx hardhat test --network localhost
```

Tests resolve the contract at the fixed `contractAddress` declared in each test file; update it if the deployment address differs. Tests are scripted walkthroughs that log balances and events and do not assert results.

## Security

Self-review of the codebase. Findings are acknowledged and left unfixed, as the code is retained as a reference.

| ID | Severity | Title | Location |
|---|---|---|---|
| C-01 | Critical | Any caller can withdraw all pooled liquidity | `add-liquidity/contracts/AddLiquidity.sol` |
| H-01 | High | No slippage protection on swaps or liquidity operations | All modules |
| H-02 | High | Deadline set to `block.timestamp` is always satisfied | All modules |
| M-01 | Medium | `optimalAmount` ignores token ordering | `optimal-swap-liquidity/contracts/optimalSwap.sol` |
| L-01 | Low | Pair existence not checked before reading reserves | `optimal-swap-liquidity/contracts/optimalSwap.sol` |
| L-02 | Low | Unchecked ERC-20 return values | All modules |
| I-01 | Info | Flash swap fee requires the contract to be pre-funded | `flash-swap/contracts/FlashSwap.sol` |

**C-01.** `Liquidity` holds LP tokens for every depositor in a single balance. `LiquidityRemove` burns the contract's entire LP balance and pays the underlying tokens to the caller. *Recommendation:* track LP shares per depositor, or mint LP tokens directly to the user.

**H-01.** Swaps pass `amountOutMin` of `0` or `1`, and `addLiquidity` and `removeLiquidity` pass minimums of `0` or `1`. Transactions are fully exposed to sandwiching. *Recommendation:* accept caller-supplied minimums.

**H-02.** Every router call uses `block.timestamp` as the deadline, which passes at any execution time. A delayed transaction executes at whatever price prevails. *Recommendation:* accept a caller-supplied deadline.

**M-01.** `optimalAmount` always reads the second reserve. When token A is `token0`, the result is computed against the wrong reserve. `swap` handles ordering correctly. *Recommendation:* select the reserve by comparing against `token0()`.

**L-01.** `optimalSwap.swap` calls `getReserves` on the result of `getPair` without checking for `address(0)`. *Recommendation:* revert when the pair does not exist.

**L-02.** Return values of `transfer` and `transferFrom` are ignored in most paths, so tokens that return `false` instead of reverting are mishandled. *Recommendation:* use `SafeERC20`.

**I-01.** The callback pays the fee from the contract's own balance, so it reverts unless the contract is funded beforehand.

## License

GPL-3.0, see [`LICENSE`](LICENSE). Files marked MIT in their SPDX header remain MIT.
