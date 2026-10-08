const {ethers} = require("hardhat")

async function main () {
     const artifacts = await ethers.getContractFactory("flashSwap");
     const deploy = await artifacts.deploy();

     console.log("address :: ", deploy.target);
}
main();