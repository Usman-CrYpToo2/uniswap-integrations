# Uniswap Integrations

[![v3](https://github.com/Usman-CrYpToo2/uniswap-integrations/actions/workflows/v3.yml/badge.svg)](https://github.com/Usman-CrYpToo2/uniswap-integrations/actions/workflows/v3.yml)

Reference integrations against the Uniswap V2 and V3 mainnet deployments, each with a structured security review.

> [!WARNING]
> Educational code. Unaudited and not intended for deployment.

## Packages

| Package | Toolchain | Scope | Security review |
|---|---|---|---|
| [`v2/`](v2) | Hardhat | Swaps, liquidity provision, optimal single-sided zap, flash swaps | 7 findings, acknowledged |
| [`v3/`](v3) | Foundry, solc 0.7.6 | Single-hop and multi-hop swaps, concentrated liquidity position management | 8 findings: 5 fixed, 3 acknowledged |

Each package has its own README covering design notes, usage, and findings.

## Highlights

- **V3-C-01 (Critical, fixed).** Unauthenticated `onERC721Received` allowed any caller to take over and drain a custodied position. The same pattern appears in the Uniswap V3 documentation example the contract is based on. See [`v3/`](v3#security-review).
- **V2-C-01 (Critical, acknowledged).** LP tokens pooled in a single balance allow any caller to withdraw all deposited liquidity. See [`v2/`](v2#security-review).

## Acknowledgements

The V3 contracts are adapted from the examples in the [Uniswap V3 developer guides](https://docs.uniswap.org/contracts/v3/guides/). The fixes, tests, and security reviews are original.

## License

GPL-3.0, see [`LICENSE`](LICENSE). Files marked MIT in their SPDX header remain MIT.
