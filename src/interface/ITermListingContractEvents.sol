// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface ITermListingContractEvents {

    event TermListingLend(
        address indexed termRepoToken, 
        address indexed purchaseToken,
        uint256 repoTokenAmount,
        uint256 purchaseTokenAmount
    );

    event TermListingClaim(
        address indexed termRepoToken, 
        address indexed purchaseToken,
        uint256 purchaseTokenProceeds
    );

    event TermListingDeposit(
        address indexed depositor,
        address indexed termRepoToken, 
        uint256 amountToDeposit, 
        uint256 updatedRepoTokenAmount, 
        uint256 updatedPurchaseTokenProceeds, 
        bool claimProceeds
    );

    event TermListingWithdraw(
        address indexed withdrawer,
        address indexed termRepoToken, 
        uint256 amountToWithdraw, 
        uint256 updatedRepoTokenAmount, 
        uint256 updatedPurchaseTokenProceeds, 
        bool claimProceeds
    );

    event RepoTokenRateUpdated(
        address indexed termRepoToken, 
        address indexed purchaseToken,
        uint256 oldRate, 
        uint256 newRate
    );

    event DiscountRateAdapterUpdated(
        address indexed oldAdapter, 
        address indexed newAdapter
    );

    event Paused();

    event Unpaused();

    event RepoTokenBlacklistUpdated(
        address indexed repoToken,
        bool blacklisted
    );
}