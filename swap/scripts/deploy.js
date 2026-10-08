const hre = require("hardhat");

async function main() {
     const swapping = await hre.ethers.getContractFactory("Swapping");
     const deploy = await swapping.deploy("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2");

     console.log("instance :: ", deploy,"\n");

     const address =await deploy.getAddress();
     console.log("address :: ", address,"\n");

     console.log("contract address which is deployeed :: ",deploy.target)


     
}

main().then(()=>{
    process.exit(0);
}).catch((err)=>{
    console.log(err)
    process.exit(0);
})