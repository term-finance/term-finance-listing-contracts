// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IRepoTokenLinkedListEvents {

    event NewListing(uint256 listingId, address seller, address token, uint256 amount);
    event Purchase(uint256 listingId, address buyer, address seller, address repoToken, uint256 amount, address purchaseToken, uint256 cost);
    event ListingCancelled(uint256 listingId, address seller, uint256 amount);

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
    
    event MinListingAmountUpdated(uint256 oldAmount, uint256 newAmount);
}