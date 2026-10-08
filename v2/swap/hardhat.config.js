require("@nomicfoundation/hardhat-toolbox");

// Set MAINNET_RPC_URL to fork Ethereum mainnet (the tests need it).
// Without it, Hardhat still compiles, but the tests have no Uniswap to talk to.
const MAINNET_RPC_URL = process.env.MAINNET_RPC_URL;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19",
  networks: {
    hardhat: MAINNET_RPC_URL ? { forking: { url: MAINNET_RPC_URL } } : {},
  },
};
