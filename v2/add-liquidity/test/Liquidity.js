const {expect} = require("chai");
const {ethers, network} = require("hardhat");

let weth ="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
let dai = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
let impersonateAccout = "0x2fEb1512183545f48f6b9C5b4EbfCaF49CfCa6F3";

let contractAddress = "0x1bEfE2d8417e22Da2E0432560ef9B2aB68Ab75Ad";


let WethInstance ;
let DaiInstance ;
let contractInstance ;
let signer1;
let signer2;

describe("getting instance", () =>{
    it("impersonating the account", async() =>{
         await network.provider.request({
             method : "hardhat_impersonateAccount",
             params : [impersonateAccout]
         })
        
        signer1 = await ethers.getSigner(impersonateAccout);
    })

    it("getting instance", async () => {
         WethInstance = await ethers.getContractAt("IERC20", weth);
         DaiInstance = await ethers.getContractAt("IERC20", dai);
         contractInstance = await ethers.getContractAt("Liquidity", contractAddress);
    })

    it ("printing " , () => {
         console.log("weth ::", WethInstance)
         console.log("\n dai instance :: ", DaiInstance);
         console.log("\n contract Instance :: ", contractInstance);
        //  console.log("\n signer :: ", signer)
    })

})


describe("adding the liquidity", () => {
     
    it("transfering the tokens to address[0]", async() => {
          signer2 = await ethers.getSigners();
          signer2 = signer2[0];

          const amountA = ethers.parseEther("10000");
          const amountB = ethers.parseEther("10");

          await WethInstance.connect(signer1).transfer(signer2.address,amountA );
          await DaiInstance.connect(signer1).transfer(signer2.address, amountB)

          // console.log(contractInstance.interface.fragments)
            
          await WethInstance.approve(contractAddress, amountA);
          await DaiInstance.approve(contractAddress, amountB);

           console.log("weth before liquidity :: ",ethers.formatEther(await WethInstance.balanceOf(signer2.address)) );
           console.log("dai before liquidity :: ", ethers.formatEther(await DaiInstance.balanceOf(signer2.address)));
        const txaddLiquidity =   await contractInstance.LiquidityAdd(weth, dai, amountA, amountB);

        const tx = await txaddLiquidity.wait();
        console.log("weth after liquidity :: ",ethers.formatEther(await WethInstance.balanceOf(signer2.address)) );
        console.log("dai after liquidity :: ", ethers.formatEther(await DaiInstance.balanceOf(signer2.address)));

        



          const contractInterface = new ethers.Interface(['event LiquidityData(string indexed message, uint256 indexed amount)']);

          // Iterate through the logs and parse them
          tx.logs.forEach((log) => {
            // Parse the log using the contract interface
            const parsedLog = contractInterface.parseLog(log);
    
            // Check if the log matches the event you're interested in
            if (parsedLog !=  null) {
              console.log('Log data:', parsedLog.args);
              // You can access specific log data using parsedLog.values
            }
          });
          
     });

})

describe("remove liquidity", () => {
   
    it("removing liquidity of weth/dai", async() => {
          
          const txremoveLiquidity = await contractInstance.LiquidityRemove(weth, dai);
          const tx = await txremoveLiquidity.wait();
          console.log("tokenA amount after Liquidity :: ", ethers.formatEther(await WethInstance.balanceOf(signer2.address)));
          console.log("tokenB amount after Liquidity :: ", ethers.formatEther(await DaiInstance.balanceOf(signer2.address)));
         const contractInterface = new ethers.Interface(['event LiquidityData(string indexed message, uint256 indexed amount)']);

         tx.logs.forEach((log) => {
             const parseLogged = contractInterface.parseLog(log);
             if(parseLogged != null){
             console.log(parseLogged.args);
             }
         })

    })
})
