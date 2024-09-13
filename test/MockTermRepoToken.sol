// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {MockERC20} from "./MockERC20.sol";
import {ITermRepoToken} from "../src/interface/ITermRepoToken.sol";
import {MockTermRepoServicer} from "./MockTermRepoServicer.sol";

contract MockTermRepoToken is MockERC20, ITermRepoToken {
    address public immutable PURCHASE_TOKEN;
    uint256 public immutable REDEMPTION_TIMESTAMP;
    MockTermRepoServicer public immutable REPO_SERVICER;
    
    bytes32 public termRepoId;

    constructor(address purchaseToken_, uint256 redemptionTimestamp_, bytes32 termRepoId_) MockERC20("TestRepoToken", "REPO") {
        PURCHASE_TOKEN = purchaseToken_;
        REDEMPTION_TIMESTAMP = redemptionTimestamp_;
        termRepoId = termRepoId_;
        REPO_SERVICER = new MockTermRepoServicer(address(this), PURCHASE_TOKEN);
    }

    function redemptionValue() external view returns (uint256) {
        return 1e18;
    }

    function config() external view returns (
        uint256 redemptionTimestamp, 
        address purchaseToken, 
        address termRepoServicer, 
        address termRepoCollateralManager
    ) {
        return (REDEMPTION_TIMESTAMP, PURCHASE_TOKEN, address(REPO_SERVICER), address(0));
    }
}