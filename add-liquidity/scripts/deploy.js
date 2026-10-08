const {ethers} = require("hardhat");

async function main(){
     const artifacts = await ethers.getContractFactory("Liquidity");
     const deployed = await artifacts.deploy();
     console.log("address :: ", await deployed.target);

}

main() ;