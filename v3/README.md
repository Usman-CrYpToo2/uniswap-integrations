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

## Security

A self-review found 8 issues: 5 fixed, including a critical position-takeover bug that is also present in the Uniswap documentation example, and 3 acknowledged. See [`audits/2026-10-v3-self-review.md`](../audits/2026-10-v3-self-review.md).

## Acknowledgements

The contracts are adapted from the examples in the [Uniswap V3 developer guides](https://docs.uniswap.org/contracts/v3/guides/). The fixes, tests, and security review are original.
