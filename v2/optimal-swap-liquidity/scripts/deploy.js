const hre = require("hardhat");

async function main() {
     const artifacts =await hre.ethers.getContractFactory("optimalSwap");
     const deploy = await artifacts.deploy() ;
      
     console.log("address :: ", deploy.target);

}

main();