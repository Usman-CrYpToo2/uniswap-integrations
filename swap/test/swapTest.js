const { expect } = require("chai");
const {ethers} = require("hardhat");

let weth ="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
let dai = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
let swapContractAddress = "0x1bEfE2d8417e22Da2E0432560ef9B2aB68Ab75Ad";

describe("testing swapping ", () => {
      let signer ;
      let WethInstance;
      let DaiInstance;
      let swapContractInstance;
      let account ;
     it("getting provider", async () =>{
          signer = await ethers.getSigners();
          account = signer[0].address;
     })

     it("getting instance of the contract", async () => {
           WethInstance = await ethers.getContractAt("IERC20",weth,signer[0]);
           DaiInstance = await ethers.getContractAt("IERC20", dai, signer[0]);
           swapContractInstance = await ethers.getContractAt("Swapping",swapContractAddress, signer[0]);
     })

     it("print", () => {
          console.log("\n WETH INSTANCE :: ", WethInstance);
          console.log("\n DAI ISTANCE :: ", DaiInstance);
          console.log("\n SWAP CONTRACT INSTANCE :: ", swapContractInstance);
     })

     it("exchanging eth for weth", async() => {
         const tx = await WethInstance.deposit({value : ethers.parseEther("1")});
         const balOfWeth = await WethInstance.balanceOf(account);
         console.log("\n balance of weth :: ", balOfWeth)
     })

     it("now swapping 1 weth for dai", async() => {
         const amountIn = ethers.parseEther("1");
         const approve = await WethInstance.approve(swapContractAddress, amountIn);
         console.log(approve)
         const tx = await swapContractInstance.exactInput(amountIn, weth, dai);
         console.log("\ntransaction :: ", tx);
          await tx.wait();
         const balanceOfDai = await DaiInstance.balanceOf(account);
         const formatDai = ethers.formatEther(balanceOfDai);
         console.log("\nbalance of dai after swapping :: ", formatDai);
         console.log("\nbalance of weth :: ", await WethInstance.balanceOf(account));
         console.log(await DaiInstance.name())

     })
})




