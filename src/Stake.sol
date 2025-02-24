// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/Errors.sol";
import "./lib/Events.sol";

contract Stake {
    address public owner;
    IERC20 public rewardToken;

    uint public poolCount;
    mapping(uint => mapping(address => StakeS)) public stakes;
    mapping(uint => Pool) public pools;

    struct StakeS {
        uint timestamp;
        uint amount;
    }

    struct Pool {
        address stakingToken;
        uint rewardPercentage;
        bool isLocked;
        uint totalStakes;
    }

    constructor(address _rewardToken) {
        owner = msg.sender;
        rewardToken = IERC20(_rewardToken);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Errors.NotTheOwner();
        _;
    }

    function createPool(
        address _token,
        uint _rewardPercentage
    ) external onlyOwner {
        if (_token == address(0)) revert Errors.InvalidAddress();
        if (_rewardPercentage == 0) revert Errors.LessThanZero();

        try IERC20(_token).totalSupply() {} catch {
            revert Errors.MustBeAnERC20Token();
        }

        poolCount++;
        pools[poolCount] = Pool({
            stakingToken: _token,
            rewardPercentage: _rewardPercentage,
            isLocked: false,
            totalStakes: 0
        });

        emit Events.PoolCreated(_token, _rewardPercentage);
    }

    function stake(uint _amount, uint _poolId) external {
        Pool storage pool = pools[_poolId];
        if (pool.stakingToken == address(0)) revert Errors.InvalidPool();
        if (stakes[_poolId][msg.sender].amount > 0) revert Errors.HasStaked();
        if (IERC20(pool.stakingToken).balanceOf(msg.sender) < _amount)
            revert Errors.InsufficientFunds();

        stakes[_poolId][msg.sender] = StakeS({
            timestamp: block.timestamp,
            amount: _amount
        });

        pool.totalStakes++;
        IERC20(pool.stakingToken).transferFrom(msg.sender, address(this), _amount);
        rewardToken.transfer(msg.sender, _amount);

        emit Events.Staked(msg.sender, _amount);
    }

    function unStake(uint _poolId) external {
        StakeS storage userStake = stakes[_poolId][msg.sender];
        Pool storage pool = pools[_poolId];

        if (userStake.amount == 0) revert Errors.HasNotStaked();
        if (rewardToken.balanceOf(msg.sender) < userStake.amount)
            revert Errors.NoRewardTokens();
        if (block.timestamp < userStake.timestamp + 2 days)
            revert Errors.LessThanTwoDays();

        uint reward = (userStake.amount * pool.rewardPercentage) / 100;
        if (IERC20(pool.stakingToken).balanceOf(address(this)) < reward)
            revert Errors.InsufficientFunds();

        delete stakes[_poolId][msg.sender];
        pool.totalStakes--;

        IERC20(pool.stakingToken).transfer(msg.sender, reward);
        emit Events.Unstaked(msg.sender, userStake.amount, reward);
    }

    function lockPool(uint _poolId) external onlyOwner {
        if (pools[_poolId].stakingToken == address(0)) revert Errors.InvalidPool();
        pools[_poolId].isLocked = true;
    }

    function getPool(uint _poolId) external view returns (Pool memory) {
        if (pools[_poolId].stakingToken == address(0)) revert Errors.InvalidPool();
        return pools[_poolId];
    }

    function getStake(uint _poolId) external view returns (StakeS memory) {
        return stakes[_poolId][msg.sender];
    }
}
