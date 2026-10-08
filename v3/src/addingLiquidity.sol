// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import "v3-periphery/libraries/TransferHelper.sol";
import "v3-periphery/interfaces/INonfungiblePositionManager.sol";
import "v3-periphery/base/LiquidityManagement.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract addingLiquidity is IERC721Receiver {
     address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

     uint24 public constant poolFee = 100;

    INonfungiblePositionManager public constant nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1; 
    }

    mapping(uint256 => Deposit) public deposits;

        // Implementing `onERC721Received` so this contract can receive custody of erc721 tokens
    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        // get position information
        console.log("operator: ", operator);
        _createDeposit(operator, tokenId);

        return this.onERC721Received.selector;
    }
     
 

    function _createDeposit(address owner, uint256 tokenId) internal {
         (, , address token0, address token1, , , , uint128 liquidity, , , , ) = nonfungiblePositionManager.positions(tokenId);
        deposits[tokenId] = Deposit({owner: owner, liquidity: liquidity, token0: token0, token1: token1});
    }

    function mintNewPosition() external returns(uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
          uint256 amount0Desired = 100000e18;
          uint256 amount1Desired = 100000e6;

          TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), amount0Desired);
            TransferHelper.safeTransferFrom(USDC, msg.sender, address(this), amount1Desired);
            TransferHelper.safeApprove(DAI, address(nonfungiblePositionManager), amount0Desired);
            TransferHelper.safeApprove(USDC, address(nonfungiblePositionManager), amount1Desired);

            INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
                token0: DAI,
                token1: USDC,
                fee: poolFee,
                tickLower: TickMath.MIN_TICK,
                tickUpper: TickMath.MAX_TICK,
                amount0Desired: amount0Desired,
                amount1Desired: amount1Desired,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),  
                deadline: block.timestamp + 1000
            });
         
            (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(params);
             console.log("msg.sender: ", msg.sender);
            _createDeposit(msg.sender, tokenId);

            if(amount0Desired > amount0) {
                TransferHelper.safeApprove(DAI, address(nonfungiblePositionManager), 0);
                TransferHelper.safeTransfer(DAI, msg.sender, amount0Desired - amount0);
            }

            if(amount1Desired > amount1) {
                TransferHelper.safeApprove(USDC, address(nonfungiblePositionManager), 0);
                TransferHelper.safeTransfer(USDC, msg.sender, amount1Desired - amount1);
            }
    }


    function collectingAllFee(uint256 tokenId) external returns(uint256 amount0, uint256 amount1){
         
         INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
    });
       (amount0, amount1) = nonfungiblePositionManager.collect(params);

        _sendToOwner(tokenId, amount0, amount1);

    }


    function increaseLiquidityCurrentRange(uint256 tokenId, uint256 amount0, uint256 anount1) external returns(uint128 liquidity, uint256 amount0Added, uint256 amount1Added) {
        TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), amount0);
        TransferHelper.safeApprove(DAI, address(nonfungiblePositionManager), amount0);
        TransferHelper.safeTransferFrom(USDC, msg.sender, address(this), anount1);
        TransferHelper.safeApprove(USDC, address(nonfungiblePositionManager), anount1); 

        INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager.IncreaseLiquidityParams({
            tokenId: tokenId,
            amount0Desired: amount0,
            amount1Desired: anount1,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp + 1000
        });

        (liquidity, amount0Added, amount1Added ) = nonfungiblePositionManager.increaseLiquidity(params);

        if(amount0 > amount0Added) {
            TransferHelper.safeApprove(DAI, address(nonfungiblePositionManager), 0);
            TransferHelper.safeTransfer(DAI, msg.sender, amount0 - amount0Added);
        }

        if(anount1 > amount1Added) {
            TransferHelper.safeApprove(USDC, address(nonfungiblePositionManager), 0);
            TransferHelper.safeTransfer(USDC, msg.sender, anount1 - amount1Added);
        }
      
    }

    function decreaseLiquidityInHalf(uint256 tokenId) external returns(uint256 amount0, uint256 amount1) {
        Deposit memory _deposit = deposits[tokenId];
        require(_deposit.owner == msg.sender, "only owner can decrease liquidity");
        console.log("liquidity: ::: ", _deposit.liquidity);
         

        INonfungiblePositionManager.DecreaseLiquidityParams memory params = INonfungiblePositionManager.DecreaseLiquidityParams({
            tokenId: tokenId,
            liquidity: _deposit.liquidity / 2,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp + 1000
        });

        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);
           INonfungiblePositionManager.CollectParams memory paramsCollectTokens = INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: address(this),
            amount0Max:  type(uint128).max,
            amount1Max: type(uint128).max
    });
       (amount0, amount1) = nonfungiblePositionManager.collect(paramsCollectTokens);
   
         _sendToOwner(tokenId, amount0, amount1);
    }
  
    function _sendToOwner(uint256 tokenId, uint256 amount0, uint256 amount1) internal {
        Deposit memory _deposit = deposits[tokenId];
        TransferHelper.safeTransfer(_deposit.token0, _deposit.owner, amount0);
        TransferHelper.safeTransfer(_deposit.token1, _deposit.owner, amount1);
     
    }
    
}
