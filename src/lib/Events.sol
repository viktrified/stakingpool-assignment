// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Events {
event Staked(address staker, uint amount);
event Unstaked(address staker, uint amount);
}