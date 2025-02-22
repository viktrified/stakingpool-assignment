// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Errors {
    error InvalidAddress();
    error LessThanZero();
    error HasStaked();
    error HasNotStaked();
    error InsufficientFunds();
    error LessThanTwoDays();
}