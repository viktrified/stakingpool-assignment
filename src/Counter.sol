// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/token/ERC20/ERC20.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "./lib/Errors.sol";
import "./lib/Events.sol";

contract Stake {
    address owner;
    ERC20 token;
    mapping(address => Stake) stakes;

    constructor(address _token) {
        owner = msg.sender;
        token = ERC20(_token);
    }

    struct Stake {
        uint timestamp;
        uint amount;
    }

    function stake(uint _amount) public {
        if(_amount < 0) revert Errors.LessThanZero();
        if(msg.sender == address(0)) revert Errors.InvalidAddress();
        if(stakes[msg.sender].amount != 0) revert Errors.HasStaked();
        if(token.balanceOf(msg.sender) < _amount) revert Errors.InsufficientFunds();

        stakes[msg.sender] = Stake({
            timestamp: block.timestamp,
            amount: _amount
        });
        token.transferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _amount);
    }

    function unStake() public {
        if(stakes[msg.sender].amount == 0) revert Errors.HasNotStaked();
        if(block.timestamp < stakes[msg.sender].timestamp + 2 days ) revert Errors.LessThanTwoDays();
        
        uint yeildAmount = (stakes[msg.sender].amount * 120)/100;
        token.transfer(msg.sender, yeildAmount);
    }

    function getStake() public view returns(Stake memory) {
        if (stakes[msg.sender].timestamp == 0 || stakes[msg.sender].amount == 0) revert Errors.HasNotStaked();

        return stakes[msg.sender];
    }
}
