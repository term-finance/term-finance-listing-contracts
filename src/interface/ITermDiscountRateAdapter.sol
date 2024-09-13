// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ITermController } from "./ITermController.sol";

interface ITermDiscountRateAdapter {
    function TERM_CONTROLLER() external view returns (ITermController);
    function getDiscountRate(address repoToken) external view returns (uint256);
}