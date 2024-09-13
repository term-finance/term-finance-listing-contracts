// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {RepoTokenLinkedListEventEmitter} from "./RepoTokenLinkedListEventEmitter.sol";
import {ITermDiscountRateAdapter} from "./interface/ITermDiscountRateAdapter.sol";
import {ITermRepoToken} from "./interface/ITermRepoToken.sol";
import {ITermRepoServicer} from "./interface/ITermRepoServicer.sol";
import {ITermController} from "./interface/ITermController.sol";

/// @title RepoTokenLinkedListStorageV1
/// @notice Storage contract for the RepoTokenLinkedList
contract RepoTokenLinkedListStorageV1 {
    /// @notice Structure to represent a token listing
    /// @dev Uses a linked list structure for efficient management
    struct Listing {
        address seller;
        address token;
        uint256 amount;
        uint256 next; // Pointer to the next listing
        uint256 prev; // Pointer to the previous listing
    }

    /// @notice Structure to represent a queue for each Repo token
    struct Queue {
        uint256 head;
        uint256 tail;
    }

    mapping(address => bool) public repoTokenBlacklist;
    mapping(address => uint256) public totalListed;  // Tracks the cumulative balance for each repoToken
    mapping(uint256 => Listing) public listings;  // Linked list storage
    mapping(address => uint256) public minimumListingAmount;  // Minimum purchase amount for each repoToken
    mapping(address => Queue) public queues;  // Queue for each Repo token

    uint256 public nextId; // Counter to assign unique IDs to listings

    uint256 public discountRateMarkup;  // Markup applied to the discount rate in RATE_PRECISION
    
    ITermDiscountRateAdapter public discountRateAdapter;
}

/// @title RepoTokenLinkedList
/// @notice A marketplace for trading repo tokens
/// @dev Implements upgradeable patterns and various security features
contract RepoTokenLinkedList is
    Initializable, 
    UUPSUpgradeable, 
    AccessControlUpgradeable, 
    ReentrancyGuardUpgradeable, 
    PausableUpgradeable,
    RepoTokenLinkedListStorageV1 
{
    using SafeERC20 for IERC20;
    using SafeERC20 for ERC20;

    ITermController public immutable TERM_CONTROLLER;

    RepoTokenLinkedListEventEmitter public immutable REPO_TOKEN_LINKED_LIST_EVENT_EMITTER;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DEVOPS_ROLE = keccak256("DEVOPS_ROLE");
    uint256 public constant RATE_PRECISION = 1e18;
    uint256 public constant MAX_MARKUP = 2e16;
    uint256 public constant REDEMPTION_VALUE_PRECISION = 1e18; // Term default is 18 decimal places
    uint256 public constant THREESIXTY_DAYCOUNT_SECONDS = 360 days;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice Contract constructor
    /// @param termController Address of the term controller contract
    /// @param repoTokenLinkedListEventEmitter Address of the event emitter contract
    constructor(
        address termController,
        address repoTokenLinkedListEventEmitter
    ) {
        _disableInitializers();
        TERM_CONTROLLER = ITermController(termController);

        // make sure term controller is valid
        require(!TERM_CONTROLLER.isTermDeployed(address(0)));

        REPO_TOKEN_LINKED_LIST_EVENT_EMITTER = RepoTokenLinkedListEventEmitter(repoTokenLinkedListEventEmitter);
    }

    /// @notice Initializes the contract with admin and devops roles
    /// @param discountRateAdapter_ The address of the discount rate oracle
    /// @param adminWallet_ The address to be granted the admin role
    /// @param devopsWallet_ The address to be granted the devops role
    /// @dev Sets up roles and initializes the contract using OpenZeppelin's upgradeable pattern
    /// @dev See: https://docs.openzeppelin.com/contracts/4.x/upgradeable
    function initialize(
        address discountRateAdapter_,
        address adminWallet_,
        address devopsWallet_
    )
    external initializer {
        UUPSUpgradeable.__UUPSUpgradeable_init();
        AccessControlUpgradeable.__AccessControl_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        PausableUpgradeable.__Pausable_init();

        discountRateAdapter = ITermDiscountRateAdapter(discountRateAdapter_);
        nextId = 1;

        minimumListingAmount[USDC] = 1000 * 1e6;  // Set a default minimum purchase amount for USDC
        minimumListingAmount[WETH] = 5 * 1e17;  // Set a default minimum purchase amount for WETH

        _grantRole(ADMIN_ROLE, adminWallet_);
        _grantRole(DEVOPS_ROLE, devopsWallet_);
    }

    /// @notice Modifier to check if a repo token is valid
    modifier onlyValidatedRepoToken(address repoToken) {
        require(isRepoTokenValid(repoToken), "RepoToken is not validated");
        _;
    }

    /// @notice Sets the blacklist status for a repo token
    /// @param repoToken The address of the repo token
    /// @param blacklisted The blacklist status to set
    function setRepoTokenBlacklist(address repoToken, bool blacklisted) external onlyRole(ADMIN_ROLE) {
        // This function can be used to blacklist or unblacklist a repoToken
        repoTokenBlacklist[repoToken] = blacklisted;
        REPO_TOKEN_LINKED_LIST_EVENT_EMITTER.emitRepoTokenBlacklistUpdated(repoToken, blacklisted);
    }

    /// @notice Sets a new discount rate adapter
    /// @param newAdapter The address of the new discount rate adapter
    function setDiscountRateAdapter(address newAdapter) external onlyRole(ADMIN_ROLE) {
        ITermDiscountRateAdapter newDiscountAdapter = ITermDiscountRateAdapter(newAdapter);
        require(address(newDiscountAdapter.TERM_CONTROLLER()) != address(0));

        REPO_TOKEN_LINKED_LIST_EVENT_EMITTER.emitDiscountRateAdapterUpdated(
            address(discountRateAdapter), newAdapter
        );
        discountRateAdapter = newDiscountAdapter;
    }

    /// @notice Sets a new value for the discount rate markup
    /// @dev Only callable by accounts with the ADMIN_ROLE
    /// @param newMarkup The new markup value to set
    function setDiscountRateMarkup(uint256 newMarkup) external onlyRole(ADMIN_ROLE) {
        require(newMarkup < MAX_MARKUP, "Markup must be less than 2%");
        
        uint256 oldMarkup = discountRateMarkup;
        discountRateMarkup = newMarkup;
    }

    function manageMinimumListing(address token, uint256 amount) external onlyRole(ADMIN_ROLE) {
        require(amount > 0, "Amount must be greater than 0");
        uint256 oldAmount = minimumListingAmount[token];
        minimumListingAmount[token] = amount;
        REPO_TOKEN_LINKED_LIST_EVENT_EMITTER.emitMinListingAmountUpdated(oldAmount, amount);
    }

    /// @notice Pauses the contract
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
        REPO_TOKEN_LINKED_LIST_EVENT_EMITTER.emitPaused();
    }

    /// @notice Unpauses the contract
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
        REPO_TOKEN_LINKED_LIST_EVENT_EMITTER.emitUnpaused();
    }

    /// @notice Creates a new listing for a repo token
    /// @param repoToken The address of the repo token to list
    /// @param amount The amount of tokens to list
    function createListing(address repoToken, uint256 amount)
        external
        nonReentrant 
        whenNotPaused
        onlyValidatedRepoToken(repoToken)
    {
        require(amount > 0, "Amount must be greater than 0");

        ITermRepoToken termRepoToken = ITermRepoToken(repoToken);
        (, address purchaseTokenAddr, ,) = termRepoToken.config();  // Ensure the repoToken is valid
        require(minimumListingAmount[purchaseTokenAddr] > 0, "No miminimum listing amount set for token");

        require(amount >= minimumListingAmount[purchaseTokenAddr], "Amount is less than minimum listing amount");

        // Transfer the tokens to the contract
        require(IERC20(repoToken).transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        uint256 listingId = nextId++;
        listings[listingId] = Listing({
            seller: msg.sender,
            token: repoToken,
            amount: amount,
            next: 0,
            prev: 0
        });

        Queue storage queue = queues[repoToken];
        if (queue.tail != 0) {
            listings[queue.tail].next = listingId;
            listings[listingId].prev = queue.tail;
        }
        queue.tail = listingId;

        if (queue.head == 0) {
            queue.head = listingId;
        }

        totalListed[repoToken] += amount;  // Increment the total listed amount for this repoToken

        REPO_TOKEN_LINKED_LIST_EVENT_EMITTER.emitNewListing(listingId, msg.sender, repoToken, amount);
    }

    /// @notice Allows a user to purchase repo tokens
    /// @param desiredAmount The amount of tokens to purchase
    /// @param repoToken The address of the repo token to purchase
    function purchase(
        uint256 desiredAmount, 
        address repoToken
    ) external nonReentrant whenNotPaused onlyValidatedRepoToken(repoToken) {
        require(desiredAmount <= totalListed[repoToken], "Desired amount exceeds total listed tokens");

        (uint256 redemptionTimestamp, address purchaseToken, ,) = ITermRepoToken(repoToken).config();
        uint256 timeToMaturity = redemptionTimestamp > block.timestamp ? redemptionTimestamp - block.timestamp : 0;

        uint256 rate = discountRateAdapter.getDiscountRate(repoToken);

        require(rate > 0 && rate < RATE_PRECISION, "Discount rate out of valid range");

        uint256 numerator = ITermRepoToken(repoToken).redemptionValue() * RATE_PRECISION * THREESIXTY_DAYCOUNT_SECONDS;
        uint256 denominator = RATE_PRECISION * THREESIXTY_DAYCOUNT_SECONDS + ((rate + discountRateMarkup) * timeToMaturity);
        uint256 pricePerToken = (numerator / denominator);

        require(pricePerToken > 0, "No valid pricePerToken calculated for the specified repoToken");

        _purchase(repoToken, purchaseToken, desiredAmount, pricePerToken);
    }

    /// @notice Internal function to handle the purchase logic
    /// @param repoToken The address of the repo token to purchase
    /// @param purchaseToken The address of the token used for purchase
    /// @param desiredAmount The amount of tokens to purchase
    /// @param pricePerToken The price per token
    function _purchase(address repoToken, address purchaseToken, uint256 desiredAmount, uint256 pricePerToken) private {
        uint256 repoTokenPrecision = 10 ** ERC20(repoToken).decimals();
        uint256 purchaseTokenPrecision = 10 ** ERC20(purchaseToken).decimals();
        uint256 remainingAmount = desiredAmount;
        Queue storage queue = queues[repoToken];
        uint256 currentListing = queue.head;

        while (currentListing != 0 && remainingAmount > 0) {
            Listing storage listing = listings[currentListing];

            require(listing.token == repoToken, "Unexpected repoToken");
            require(listing.amount > 0, "Unexpected empty listing");

            uint256 purchaseAmount = remainingAmount > listing.amount ? listing.amount : remainingAmount;
            uint256 cost = (pricePerToken * purchaseAmount) / REDEMPTION_VALUE_PRECISION;
            cost = (cost * purchaseTokenPrecision) / repoTokenPrecision;

            listing.amount -= purchaseAmount;
            totalListed[repoToken] -= purchaseAmount;
            remainingAmount -= purchaseAmount;

            _emitAndTransfer(
                currentListing,
                purchaseToken,
                listing.seller,
                listing.token,
                purchaseAmount,
                cost
            );

            if (listing.amount == 0) {
                uint256 nextListing = listing.next;
                removeListing(repoToken, currentListing);
                currentListing = nextListing;
            } else {
                currentListing = listing.next;
            }
        }

        require(remainingAmount == 0, "Not enough tokens available to fulfill the purchase");
    }

    function _emitAndTransfer(
        uint256 currentListing,
        address purchaseToken,
        address seller,
        address token,
        uint256 purchaseAmount,
        uint256 cost
    ) private {
        REPO_TOKEN_LINKED_LIST_EVENT_EMITTER.emitPurchase(
            currentListing,
            msg.sender,
            seller,
            token,
            purchaseAmount,
            purchaseToken,
            cost
        );

        require(IERC20(purchaseToken).transferFrom(msg.sender, seller, cost), "Payment transfer failed");
        require(IERC20(token).transfer(msg.sender, purchaseAmount), "Token transfer failed");
    }

    /// @notice Allows a seller to cancel their listing
    /// @param listingId The ID of the listing to cancel
    /// @param skipRedeem Whether to skip the redeem process
    function cancelListing(uint256 listingId, bool skipRedeem) public nonReentrant whenNotPaused {
        require(listingId < nextId, "Listing does not exist");  // Ensure the listing exists
        Listing storage listing = listings[listingId];
        require(listing.seller == msg.sender || hasRole(ADMIN_ROLE, msg.sender), "Only the seller can cancel this listing");

        uint256 amount = listing.amount;
        address token = listing.token;
        address seller = listing.seller;

        totalListed[token] -= amount;  // Decrement the total listed amount     

        // Remove the listing from the linked list
        removeListing(token, listingId);

        (uint256 redemptionTimestamp, address purchaseToken, address termRepoServicer,) = ITermRepoToken(token).config();
        uint256 currentBalance = IERC20(token).balanceOf(address(this));

        // Handle edge case if someone inadverdently redeems repoToken on behalf of listing contract
        /// @notice Repotokens can be redeemed by anyone on behalf of any third-party 
        if (currentBalance < amount) {
            // Partial balance scenario
            uint256 availableAmount = currentBalance;

            // Transfer available repoTokens
            require(IERC20(token).transfer(seller, availableAmount), "RepoToken transfer failed");

            // Calculate and transfer the remaining value in purchaseTokens
            uint256 missingAmount = amount - availableAmount;
            uint256 redemptionValue = ITermRepoToken(token).redemptionValue();
            uint256 purchaseTokenAmount = (missingAmount * redemptionValue) / REDEMPTION_VALUE_PRECISION; 

            ITermRepoServicer termRepoServicer = ITermRepoServicer(termRepoServicer);
            if (termRepoServicer.shortfallHaircutMantissa() == 0) {
                require(IERC20(purchaseToken).transfer(seller, purchaseTokenAmount), "PurchaseToken transfer failed");
            } else {
                // Adjust purchaseTokenAmount for shortfallHaircutMantissa
                uint256 proRataRedemptionAmount = (purchaseTokenAmount * termRepoServicer.shortfallHaircutMantissa()) / RATE_PRECISION;
                require(IERC20(purchaseToken).transfer(seller, proRataRedemptionAmount), "PurchaseToken transfer failed");
            }

        } else {
            // Full balance available
            require(IERC20(token).transfer(seller, amount), "Token transfer failed");
        }
        
        // If past maturity, redeem on behalf of user
        if (!skipRedeem && redemptionTimestamp < block.timestamp) {
            try ITermRepoServicer(termRepoServicer).redeemTermRepoTokens(
                seller, 
                currentBalance < amount ? currentBalance : amount
            ) {
                // redemption succeeded
            } catch {
                // redemption failed, do not remove token from the list
            }
        }
        REPO_TOKEN_LINKED_LIST_EVENT_EMITTER.emitListingCancelled(listingId, seller, amount);
    }

    function batchCancelListings(uint256[] calldata listingIds, bool skipRedeem) external {
        for (uint256 i = 0; i < listingIds.length; i++) {
            cancelListing(listingIds[i], skipRedeem);
        }
    }

    /// @notice Internal function to remove a listing
    /// @param repoToken The address of the repo token    
    /// @param listingId The ID of the listing to remove
    function removeListing(address repoToken, uint256 listingId) internal {
        Listing storage listing = listings[listingId];
        Queue storage queue = queues[repoToken];

        require(listing.token == repoToken, "Unexpected repoToken");

        if (listing.prev != 0) {
            listings[listing.prev].next = listing.next;
        } else {
            queue.head = listing.next; // Update head if necessary
        }

        if (listing.next != 0) {
            listings[listing.next].prev = listing.prev;
        } else {
            queue.tail = listing.prev; // Update tail if necessary
        }

        delete listings[listingId];
    }

    /// @notice Retrieves the details of a listing
    /// @param listingId The ID of the listing to retrieve
    /// @return seller The address of the seller
    /// @return token The address of the token being sold
    /// @return amount The amount of tokens being sold
    function getListing(uint256 listingId) external view returns (address seller, address token, uint256 amount) {
        require(listingId < nextId, "Listing does not exist");  // Ensure the listing exists
        Listing storage listing = listings[listingId];
        return (listing.seller, listing.token, listing.amount);
    }

    /// @notice Gets the total number of active listings
    /// @param repoToken The address of the repo token
    /// @return The total number of listings
    function getTotalListings(address repoToken) external view returns (uint256) {
        // Traversing the linked list to count total listings
        uint256 count = 0;
        Queue storage queue = queues[repoToken];        
        uint256 currentListing = queue.head;
        while (currentListing != 0) {
            count++;
            currentListing = listings[currentListing].next;
        }
        return count;
    }

    /// @notice Checks if a repo token is valid
    /// @param repoToken The address of the repo token to check
    /// @return bool indicating if the repo token is valid
    function isRepoTokenValid(address repoToken) public view returns (bool) {
        // Check if the repoToken is blacklisted
        if (repoTokenBlacklist[repoToken]) {
            return false;
        }

        // Check if the repoToken is deployed by the TERM_CONTROLLER
        if (!TERM_CONTROLLER.isTermDeployed(repoToken)) {
            return false;
        }

        // Check the redemption timestamp to ensure the repoToken is still valid
        (uint256 redemptionTimestamp, , , ) = ITermRepoToken(repoToken).config();
        if (redemptionTimestamp < block.timestamp) {
            return false;
        }

        return true;
    }

// =========================================================================
// = Upgradeability ========================================================
// =========================================================================

    /// @notice Ensures only authorized addresses can upgrade the contract
    /// @param newImplementation The address of the new contract implementation
    /// @dev Overrides the UUPSUpgradeable _authorizeUpgrade function to include role checks.
    // solhint-disable no-empty-blocks
    ///@dev required override by the OpenZeppelin UUPS module
    function _authorizeUpgrade(
        address
    ) internal view override onlyRole(DEVOPS_ROLE) {}
    // solhint-enable no-empty-blocks    
}
