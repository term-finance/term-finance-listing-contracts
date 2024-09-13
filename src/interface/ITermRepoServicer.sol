// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface ITermRepoServicer {
    function shortfallHaircutMantissa() external view returns (uint256);
    
    function redeemTermRepoTokens(
        address redeemer,
        uint256 amountToRedeem
    ) external;
    
    function termRepoToken() external view returns (address);

    function purchaseToken() external view returns (address);
}
