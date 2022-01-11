// SPDX-License-Identifier: mit
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './interfaces/ILendingPool.sol';
import './interfaces/ILendingPoolAddressesProvider.sol';
import './interfaces/IProtocolDataProvider.sol';
import './interfaces/IUniswapV2Router02.sol';


contract TokenCity is Ownable {

    IUniswapV2Router02 public immutable uniswapV2Router;

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
        uniswapV2Router = _uniswapV2Router;
    }

    /**
    * Deposits into the Aave.
    * @param asset The asset to be deposited as collateral.
    * @param amount The amount to be deposited as collateral.
    */
    function deposit(address asset, uint256 amount) public {
        uint16 referral = 0;

        // Retrieve LendingPool address
        ILendingPoolAddressesProvider lendingProvider = ILendingPoolAddressesProvider(asset);
        ILendingPool lendingPool = ILendingPool(lendingProvider.getLendingPool());

        // Transfer, approve and deposit.
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        IERC20(asset).approve(address(lendingPool), amount);
        lendingPool.deposit(asset, amount, address(this), referral);
    }

    /**
    * Withdraw all.
    * @param asset The asset to withdraw.
    * @param ethAmount The amount of ETH to provide liquidity.
    */
    function withdrawAndProvideLiquidity(address asset, uint256 ethAmount) public onlyOwner {
        // Retrieve LendingPool address
        ILendingPoolAddressesProvider lendingProvider = ILendingPoolAddressesProvider(asset);
        ILendingPool lendingPool = ILendingPool(lendingProvider.getLendingPool());
        IProtocolDataProvider dataProvider = IProtocolDataProvider(asset);

        // Withdraw All
        (address tokenAddress,,) = dataProvider.getReserveTokensAddresses(asset);
        uint256 assetBalance = IERC20(tokenAddress).balanceOf(address(this));
        lendingPool.withdraw(asset, assetBalance, owner());

        // Provide Liquidity
        addLiquidity(asset, assetBalance, ethAmount);
    }

    /**
    * Adds liquidity to uniswap for the given asst and ETH.
    * @param asset The asset address.
    * @param tokenAmount The amount of the token.
    * @param ethAmount The amount of ETH to provide liquidity.
    */
    function addLiquidity(address asset, uint256 tokenAmount, uint256 ethAmount) internal {
        // Approve asset transfer
        IERC20(asset).approve(address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

}
