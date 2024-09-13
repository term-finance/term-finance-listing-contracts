// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract MockPot {

    uint256 public dsr;

    constructor(uint256 supplyRate_) {
        dsr = supplyRate_;
    }

    function setSupplyRate(uint256 newRate) external {
        dsr = newRate;
    }
}
