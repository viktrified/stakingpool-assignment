// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/Stake.sol";

contract StakeScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address rewardTokenAddress = vm.envAddress("REWARD_TOKEN_ADDRESS");
        address stakingTokenAddress = vm.envAddress("STAKING_TOKEN_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the Stake contract
        Stake stakeContract = new Stake(rewardTokenAddress);

        // Create a new pool
        stakeContract.createPool(stakingTokenAddress, 10); // 10% reward

        // Stake tokens into the pool
        uint256 poolId = 1;
        uint256 stakeAmount = 100 ether;
        stakeContract.stake(stakeAmount, poolId);

        // Unstake tokens from the pool
        vm.warp(block.timestamp + 3 days); // Simulate time passing
        stakeContract.unStake(poolId);

        // Lock the pool
        stakeContract.lockPool(poolId);

        // Get pool and stake details
        Stake.Pool memory pool = stakeContract.getPool(poolId);
        Stake.StakeS memory userStake = stakeContract.getStake(poolId);

        vm.stopBroadcast();
    }
}