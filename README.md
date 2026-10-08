# Uniswap Integrations

[![v3](https://github.com/Usman-CrYpToo2/uniswap-integrations/actions/workflows/v3.yml/badge.svg)](https://github.com/Usman-CrYpToo2/uniswap-integrations/actions/workflows/v3.yml)

Reference integrations against the Uniswap V2 and V3 mainnet deployments, each with a structured security review.

> [!WARNING]
> Educational code. Unaudited and not intended for deployment.

## Packages

| Package | Toolchain | Scope |
|---|---|---|
| [`v2/`](v2) | Hardhat | Swaps, liquidity provision, optimal single-sided zap, flash swaps |
| [`v3/`](v3) | Foundry, solc 0.7.6 | Single-hop and multi-hop swaps, concentrated liquidity position management |

Each package has its own README covering design notes and usage.

## Security

Self-reviews for each package are in [`audits/`](audits):

| Package | Review | Findings |
|---|---|---|
| V2 | [`2026-10-v2-self-review.md`](audits/2026-10-v2-self-review.md) | 7, acknowledged |
| V3 | [`2026-10-v3-self-review.md`](audits/2026-10-v3-self-review.md) | 8: 5 fixed, 3 acknowledged |

## Acknowledgements

The V3 contracts are adapted from the examples in the [Uniswap V3 developer guides](https://docs.uniswap.org/contracts/v3/guides/). The fixes, tests, and security reviews are original.

## License

GPL-3.0, see [`LICENSE`](LICENSE). Files marked MIT in their SPDX header remain MIT.
