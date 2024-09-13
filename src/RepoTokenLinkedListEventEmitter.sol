// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./interface/IRepoTokenLinkedListEvents.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


/// @title Token Marketplace Event Emitter
/// @notice Handles the emission of events for the term token marketplace contract system.
/// @dev This contract extends OpenZeppelin's upgradeable contract suite for access control and upgradeability, implementing the ITokenMarketplaceEvents interface.
contract RepoTokenLinkedListEventEmitter is Initializable, UUPSUpgradeable, AccessControlUpgradeable, IRepoTokenLinkedListEvents {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DEVOPS_ROLE = keccak256("DEVOPS_ROLE");
    bytes32 public constant LISTING_CONTRACT = keccak256("LISTING_CONTRACT");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with admin and devops wallets
    /// @param adminWallet_ Address of the admin wallet
    /// @param devopsWallet_ Address of the devops wallet
    /// @dev Initializes upgradeability features and sets up initial roles.
    /// @dev See: https://docs.openzeppelin.com/contracts/4.x/upgradeable
    function initialize(
        address adminWallet_,
        address devopsWallet_
    )
    external initializer {
        UUPSUpgradeable.__UUPSUpgradeable_init();
        AccessControlUpgradeable.__AccessControl_init();

        _grantRole(ADMIN_ROLE, adminWallet_);
        _grantRole(DEVOPS_ROLE, devopsWallet_);
    }

    /// @notice Assigns the LISTING_CONTRACT role to a listing contract address
    /// @param listingContract Address of the listing contract to pair
    /// @dev Only ADMIN_ROLE can call this function to pair a listing contract for event emission.
    function pairListingContract(address listingContract) external onlyRole(ADMIN_ROLE){
        _grantRole(LISTING_CONTRACT, listingContract);
    }

    
    /**
     * @notice Emits an event for a new listing.
     * @param listingId The ID of the listing.
     * @param seller The address of the seller.
     * @param repoToken The address of the repo token.
     * @param amount The amount of the repo token.
     */
    /// @dev Restricted to only addresses with the LISTING_CONTRACT role.
    function emitNewListing(
        uint256 listingId, 
        address seller, 
        address repoToken, 
        uint256 amount
    ) external onlyRole(LISTING_CONTRACT) {
        emit NewListing(listingId, seller, repoToken, amount);
    }


    /**
     * @dev Emits a purchase event with the given parameters.
     * @param listingId The ID of the listing.
     * @param buyer The address of the buyer.
     * @param seller The address of the seller.
     * @param repoToken The address of the repo token.
     * @param amount The amount of tokens purchased.
     * @param purchaseToken The address of the purchase token.     
     * @param cost The cost of amount in purchase token.
     */
    /// @dev Restricted to only addresses with the LISTING_CONTRACT role.
    function emitPurchase(
        uint256 listingId, 
        address buyer, 
        address seller,
        address repoToken,
        uint256 amount,
        address purchaseToken,
        uint256 cost
    ) external onlyRole(LISTING_CONTRACT) {
        emit Purchase(listingId, buyer, seller, repoToken, amount, purchaseToken, cost);
    }

    /**
     * @dev Emits an event when a listing is cancelled.
     * @param listingId The ID of the cancelled listing.
     * @param seller The address of the seller.
     * @param amount The amount of tokens cancelled.
     */
    /// @dev Restricted to only addresses with the LISTING_CONTRACT role.
    function emitListingCancelled(
        uint256 listingId,
        address seller,
        uint256 amount
    ) external onlyRole(LISTING_CONTRACT) {
        emit ListingCancelled(listingId, seller, amount);
    }

    function emitDiscountRateAdapterUpdated(
        address oldAdapter,
        address newAdapter
    ) external onlyRole(LISTING_CONTRACT) {
        emit DiscountRateAdapterUpdated(oldAdapter, newAdapter);
    }

    function emitPaused() external onlyRole(LISTING_CONTRACT) {
        emit Paused();
    }

    function emitUnpaused() external onlyRole(LISTING_CONTRACT) {
        emit Unpaused();
    }

    function emitRepoTokenBlacklistUpdated(address repoToken, bool blacklisted) external onlyRole(LISTING_CONTRACT) {
        emit RepoTokenBlacklistUpdated(repoToken, blacklisted);
    }

    function emitMinListingAmountUpdated(uint256 oldAmount, uint256 newAmount) external onlyRole(LISTING_CONTRACT) {
        emit MinListingAmountUpdated(oldAmount, newAmount);
    }

    // ========================================================================
    // = Admin  ===============================================================
    // ========================================================================

    // solhint-disable no-empty-blocks
    /// @notice Ensures that only authorized addresses can upgrade the contract
    /// @dev Overrides the UUPSUpgradeable _authorizeUpgrade function to include a role check.    
    /// @dev required override by the OpenZeppelin UUPS module
    function _authorizeUpgrade(
        address
    ) internal view override onlyRole(DEVOPS_ROLE) {}
    // solhint-enable no-empty-blocks
}