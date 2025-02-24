// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/Stake.sol";

contract StakeTest is Test {
    Stake stakeContract;
    address owner = address(0x123);
    address user = address(0x456);
    address rewardToken = address(0x789);
    address stakingToken = address(0xABC);

    function setUp() public {
        vm.prank(owner);
        stakeContract = new Stake(rewardToken);

        // Mock ERC20 tokens
        vm.mockCall(rewardToken, abi.encodeWithSelector(IERC20.balanceOf.selector), abi.encode(1000 ether));
        vm.mockCall(stakingToken, abi.encodeWithSelector(IERC20.balanceOf.selector), abi.encode(1000 ether));
        vm.mockCall(stakingToken, abi.encodeWithSelector(IERC20.transferFrom.selector), abi.encode(true));
        vm.mockCall(stakingToken, abi.encodeWithSelector(IERC20.transfer.selector), abi.encode(true));
    }

    function test_Owner() public {
        assertEq(stakeContract.owner(), owner);
    }

    function test_RewardToken() public {
        assertEq(address(stakeContract.rewardToken()), rewardToken);
    }

    function test_OnlyOwnerCanCreatePool() public {
        vm.prank(user);
        vm.expectRevert("NotTheOwner");
        stakeContract.createPool(stakingToken, 10);
    }

    function test_CreatePool() public {
        vm.prank(owner);
        stakeContract.createPool(stakingToken, 10);

        Stake.Pool memory pool = stakeContract.getPool(1);
        assertEq(pool.stakingToken, stakingToken);
        assertEq(pool.rewardPercentage, 10);
        assertEq(pool.isLocked, false);
        assertEq(pool.totalStakes, 0);
    }

    function test_CreatePoolChecks() public {
        vm.prank(owner);
        vm.expectRevert("InvalidAddress");
        stakeContract.createPool(address(0), 10);

        vm.expectRevert("LessThanZero");
        stakeContract.createPool(stakingToken, 0);

        vm.mockCall(stakingToken, abi.encodeWithSelector(IERC20.totalSupply.selector), abi.encode(0));
        vm.expectRevert("MustBeAnERC20Token");
        stakeContract.createPool(stakingToken, 10);
    }

    function test_Stake() public {
        vm.prank(owner);
        stakeContract.createPool(stakingToken, 10);

        vm.prank(user);
        stakeContract.stake(100 ether, 1);

        Stake.StakeS memory userStake = stakeContract.getStake(1);
        assertEq(userStake.amount, 100 ether);
    }

    function test_StakeChecks() public {
        vm.prank(owner);
        stakeContract.createPool(stakingToken, 10);

        vm.prank(user);
        vm.expectRevert("InvalidPool");
        stakeContract.stake(100 ether, 2);

        stakeContract.stake(100 ether, 1);
        vm.expectRevert("HasStaked");
        stakeContract.stake(100 ether, 1);

        vm.mockCall(stakingToken, abi.encodeWithSelector(IERC20.balanceOf.selector), abi.encode(0));
        vm.expectRevert("InsufficientFunds");
        stakeContract.stake(100 ether, 1);
    }

    function test_UnStake() public {
        vm.prank(owner);
        stakeContract.createPool(stakingToken, 10);

        vm.prank(user);
        stakeContract.stake(100 ether, 1);

        vm.warp(block.timestamp + 3 days); // Simulate time passing
        stakeContract.unStake(1);

        Stake.StakeS memory userStake = stakeContract.getStake(1);
        assertEq(userStake.amount, 0);
    }

    function test_UnStakeChecks() public {
        vm.prank(owner);
        stakeContract.createPool(stakingToken, 10);

        vm.prank(user);
        vm.expectRevert("HasNotStaked");
        stakeContract.unStake(1);

        stakeContract.stake(100 ether, 1);
        vm.expectRevert("LessThanTwoDays");
        stakeContract.unStake(1);

        vm.warp(block.timestamp + 3 days);
        vm.mockCall(rewardToken, abi.encodeWithSelector(IERC20.balanceOf.selector), abi.encode(0));
        vm.expectRevert("NoRewardTokens");
        stakeContract.unStake(1);

        vm.mockCall(stakingToken, abi.encodeWithSelector(IERC20.balanceOf.selector), abi.encode(0));
        vm.expectRevert("InsufficientFunds");
        stakeContract.unStake(1);
    }

    function test_LockPool() public {
        vm.prank(owner);
        stakeContract.createPool(stakingToken, 10);

        stakeContract.lockPool(1);
        Stake.Pool memory pool = stakeContract.getPool(1);
        assertEq(pool.isLocked, true);
    }

    function test_GetPool() public {
        vm.prank(owner);
        stakeContract.createPool(stakingToken, 10);

        Stake.Pool memory pool = stakeContract.getPool(1);
        assertEq(pool.stakingToken, stakingToken);
    }

    function test_GetStake() public {
        vm.prank(owner);
        stakeContract.createPool(stakingToken, 10);

        vm.prank(user);
        stakeContract.stake(100 ether, 1);

        Stake.StakeS memory userStake = stakeContract.getStake(1);
        assertEq(userStake.amount, 100 ether);
    }
}