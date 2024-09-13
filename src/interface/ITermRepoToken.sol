// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITermRepoToken is IERC20 {
    function redemptionValue() external view returns (uint256);

    function config() external view returns (
        uint256 redemptionTimestamp, 
        address purchaseToken, 
        address termRepoServicer, 
        address termRepoCollateralManager
    );

    function termRepoId() external view returns (bytes32);
}
