const {ethers} = require("hardhat");



let weth ="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
let dai = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
let contractAddress = "0x1bEfE2d8417e22Da2E0432560ef9B2aB68Ab75Ad";

describe("testing the flashSwap ", () => {
  let signer;
  let wethInstance;
  let daiInstance;
  let contractInstance ;

     it("getting signer and instance", async() => {
          signer = await ethers.getSigners();
          signer = signer[0];

          wethInstance = await ethers.getContractAt("IERC20", weth, signer);
          daiInstance = await ethers.getContractAt("IERC20", dai, signer);

          contractInstance = await ethers.getContractAt("flashSwap", contractAddress, signer);

          // console.log("\nwethInstance :: ", wethInstance);
          // console.log("\ndaiInstance :: ", daiInstance);
          // console.log("contract instance :: ", contractInstance);
     })

     it("buying some weth" ,async() => {
      val = {
         value : ethers.parseEther("2"),
      }
         await wethInstance.deposit(val);
         console.log("balance of weth :: ", ethers.formatEther(await wethInstance.balanceOf(signer.address)));
     });
    
     it("transferring the weth to Flash Swap address" , async() => {
          val = ethers.parseEther("2");
          await wethInstance.transfer(contractAddress, val);
          console.log("balance of weth of flash swap address :: ", ethers.formatEther(await wethInstance.balanceOf(contractAddress)));
     })

     it("now borrowing 1 weth", async() => {
        val = ethers.parseEther("1");
        const borrow =  await contractInstance.testFlashSwap(weth, dai, val);
        const tx = await borrow.wait();
         const eventInterface = new ethers.Interface(["event log(string indexed message, uint indexed value)"]);

         tx.logs.forEach((log) => {
          // Parse the log using the contract interface
          const parsedLog = eventInterface.parseLog(log);
  
          // Check if the log matches the event you're interested in
            if(parsedLog != null){
            console.log('Log data:', parsedLog.args);
            }
            // You can access specific log data using parsedLog.values
     
        });
     })

})