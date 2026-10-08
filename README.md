# Uniswap V2 Integrations

Four small Solidity contracts that integrate with Uniswap V2 on Ethereum mainnet: a token swap, adding and removing liquidity, an optimal "zap" swap, and a flash swap. Each one is tested against a local fork of mainnet, so it talks to the real Uniswap V2 router, factory, and pools.

I built these in 2023 while learning how Uniswap V2 works from the integrator's side. Later, as a smart contract auditor, I came back and reviewed them. That review is in [Known limitations](#known-limitations) below.

## Modules

| Folder | Contract | What it does |
|---|---|---|
| [`swap/`](swap) | `Swapping` | Swaps an exact amount of one token for another through the Uniswap V2 router (`swapExactTokensForTokens`). |
| [`add-liquidity/`](add-liquidity) | `Liquidity` | Adds liquidity to a pair through the router, refunds any tokens the pool did not take, and removes the liquidity again. |
| [`optimal-swap-liquidity/`](optimal-swap-liquidity) | `optimalSwap` | Works out exactly how much of token A to swap into token B so that what is left can be added as liquidity with almost nothing left over. |
| [`flash-swap/`](flash-swap) | `flashSwap` | Borrows tokens from a pair with no upfront collateral and repays them, plus the 0.3% fee, in the same transaction. |

All modules use the canonical mainnet Uniswap V2 contracts:

- Router: `0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D`
- Factory: `0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f`

## How the interesting parts work

### Optimal swap amount (the "zap")

To add liquidity you need both tokens in the same ratio as the pool. If you only hold token A, the naive approach is to swap half of it. That leaves leftovers, because the swap itself moves the price and pays a 0.3% fee.

The contract instead solves for the exact swap amount `s`, given the pool's reserve of token A `r` and the amount you hold `a`:

```
s = ( sqrt( r * (3988009 * r + 3988000 * a) ) - 1997 * r ) / 1994
```

The constants come from the 0.3% fee (997 / 1000) built into the constant product formula. The square root uses the Babylonian method, in `contracts/Interfaces/Library.sol`.

### Flash swap

`testFlashSwap` calls `pair.swap(...)` with a non-empty `data` argument. That tells the pair to send the tokens first and then call back `uniswapV2Call` on this contract. Inside the callback the contract:

1. Checks that the caller is the real pair from the factory, and that it started the swap itself.
2. Works out the fee: `amount * 3 / 997 + 1`.
3. Repays `amount + fee` to the pair before the transaction ends.

If the repayment is short, the pair reverts the whole transaction. That is what makes flash swaps safe for the pool.

## Running it

Each folder is its own Hardhat project. The tests fork Ethereum mainnet, so you need a mainnet RPC URL (from Alchemy, Infura, or any provider).

```bash
cd swap                                  # or any other module
npm install
export MAINNET_RPC_URL="https://your-mainnet-rpc-url"

# terminal 1: start a local mainnet fork
npx hardhat node

# terminal 2: deploy, then run the test against the fork
npx hardhat run scripts/deploy.js --network localhost
npx hardhat test --network localhost
```

The test files call the contract at a fixed address (`contractAddress` at the top of each test). If the deploy script prints a different address, put that address into the test file.

The tests are scripted walkthroughs. They impersonate or fund accounts, run each action on the fork, and print balances and emitted events. They do not use assertions, so read the output to check the result.

## Known limitations

These contracts were written for learning and are not safe to deploy. Reviewing them now, these are the issues I would report in an audit:

**Critical**
- **Anyone can withdraw everyone's liquidity** (`add-liquidity/Liquidity.sol`). The contract keeps the LP tokens for all users in one balance, and `LiquidityRemove` sends the contract's entire LP balance to whoever calls it. It needs per-user accounting, or should send the LP tokens straight to the user.

**High**
- **No slippage protection anywhere.** Swaps use a minimum output of `0` or `1`, and liquidity calls accept any amounts. A sandwich attack can take most of the value.
- **No real deadline.** Every router call passes `block.timestamp`, which always passes. A transaction can sit in the mempool and execute later at a much worse price.

**Medium and low**
- `optimalAmount()` always reads the second reserve, so it returns a wrong value when token A is `token0` in the pair. `swap()` handles this correctly.
- `optimalSwap.swap()` does not check that the pair exists before reading it.
- `transferFrom` and `transfer` return values are not checked in most places, so tokens that return `false` instead of reverting are not handled.
- The flash swap contract must be pre-funded with enough of the token to cover the fee.

A safer version would take `minAmountOut` and `deadline` from the caller, use OpenZeppelin's `SafeERC20`, and never pool users' LP tokens in one balance.

## Tech

Solidity, Hardhat, ethers.js v6, mainnet forking.
