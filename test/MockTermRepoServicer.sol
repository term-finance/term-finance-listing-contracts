// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITermRepoServicer} from "../src/interface/ITermRepoServicer.sol";

contract MockTermRepoServicer is ITermRepoServicer {
    address public immutable termRepoToken;
    address public immutable purchaseToken;

    constructor(address repoToken_, address purchaseToken_) {
        termRepoToken = repoToken_;
        purchaseToken = purchaseToken_;
    }

    function shortfallHaircutMantissa() external view returns (uint256) {
        return 0;
    }

    function redeemTermRepoTokens(
        address redeemer,
        uint256 amountToRedeem
    ) external {

    }
}