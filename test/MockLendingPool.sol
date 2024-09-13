// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ILendingPool} from "../src/interface/aave/ILendingPool.sol";

contract MockLendingPool {

    uint128 public supplyRate;

    constructor(uint128 supplyRate_) {
        supplyRate = supplyRate_;
    }

    function setSupplyRate(uint128 newRate) external {
        supplyRate = newRate;
    }

    function getReserveData(address asset) external view returns (ILendingPool.ReserveData memory data) {
        data.currentLiquidityRate = supplyRate;
    }
}