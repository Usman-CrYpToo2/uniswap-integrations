const {expect} = require("chai");
const {ethers} = require("hardhat");

let weth ="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
let dai = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
let contractAddress = "0x1bEfE2d8417e22Da2E0432560ef9B2aB68Ab75Ad";

describe("first testing the optimal swap for tokenB", () => {
  let signer;
  let wethInstance;
  let daiInstance ;
  let contractInstance;

  it("get signer and instances", async() => {
     signer = await ethers.getSigners();
     signer = signer[0];
     wethInstance = await ethers.getContractAt("IERC20", weth, signer);
     daiInstance = await ethers.getContractAt("IERC20", dai, signer);
     contractInstance = await ethers.getContractAt("optimalSwap", contractAddress, signer);

    //  console.log("\n weth :: ", wethInstance);
    //  console.log("\n dai :: ", daiInstance);
    //  console.log("\n contract :: ", contractInstance);
    //  console.log(signer)
  });

  it("buying weth ::", async () => {
       const val = {
         value : ethers.parseEther("10"),
       }
       await wethInstance.deposit(val);

       console.log(await wethInstance.balanceOf(signer.address));
  });
 
   it("swap the tokenA for tokenB(from weth to dai)", async() => {
        const getWethBal = await wethInstance.balanceOf(signer.address);
        await wethInstance.approve(contractAddress, getWethBal);
        await contractInstance.swap(weth, dai, getWethBal);
         const val =await contractInstance.optimalAmount(weth, dai, getWethBal);
        console.log("bal of weth after the swap :: ", ethers.formatEther(await wethInstance.balanceOf(signer.address)));
        console.log("bal of dai :: ", ethers.formatEther(await daiInstance.balanceOf(signer.address)));
        console.log("val :: ", ethers.formatEther(val));
   })
   
   it("adding liquidity", async() => {
        const wethBal = await wethInstance.balanceOf(signer.address);
        const daiBal = await daiInstance.balanceOf(signer.address);
        console.log("before weth bal :: ", wethBal);
        console.log("before dai bal :: ", daiBal);
         
         await wethInstance.approve(contractAddress, wethBal);
         await daiInstance.approve(contractAddress, daiBal);

        await contractInstance.LiquidityAdd(weth, dai, wethBal, daiBal);
        
        const wethBal1 = await wethInstance.balanceOf(signer.address);
        const daiBal1 = await daiInstance.balanceOf(signer.address);
        console.log("after bal weth :: ", wethBal1);
        console.log("after dai bal :: ", daiBal1);
   })

    
})