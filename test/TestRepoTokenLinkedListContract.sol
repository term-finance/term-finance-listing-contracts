// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import "./RepoTokenLinkedListTestBase.sol";
import "forge-std/console2.sol";

contract TestRepoTokenLinkedListContract is RepoTokenLinkedListTestBase {

    function setUp() public override {
        super.setUp();
    }

    function testCreateListing_SingleDepositor(uint256 amount) public {
        amount = bound(amount, listingContract.minimumListingAmount(address(purchaseToken)), MAX_DEPOSIT_AMOUNT);

        vm.prank(depositors[0]);
        listingContract.createListing(address(repoToken1), amount);

        assertEq(listingContract.nextId(), 2);
        assertEq(listingContract.totalListed(address(repoToken1)), amount);
        assertEq(listingContract.getTotalListings(address(repoToken1)), 1);
    }

    function testCreateListing_2Depositors_SameRepoToken(uint256 amount1, uint256 amount2) public {
        amount1 = bound(amount1, listingContract.minimumListingAmount(address(purchaseToken)), MAX_DEPOSIT_AMOUNT);
        amount2 = bound(amount2, listingContract.minimumListingAmount(address(purchaseToken)), MAX_DEPOSIT_AMOUNT);

        vm.prank(depositors[0]);
        listingContract.createListing(address(repoToken1), amount1);

        vm.prank(depositors[1]);
        listingContract.createListing(address(repoToken1), amount2);

        assertEq(listingContract.nextId(), 3);
        assertEq(listingContract.totalListed(address(repoToken1)), amount1 + amount2);
        assertEq(listingContract.getTotalListings(address(repoToken1)), 2);
    }

    function testCreateListing_2Depositors_DifferentRepoTokens(uint256 amount1, uint256 amount2) public {
        amount1 = bound(amount1, listingContract.minimumListingAmount(address(purchaseToken)), MAX_DEPOSIT_AMOUNT);
        amount2 = bound(amount2, listingContract.minimumListingAmount(address(purchaseToken)), MAX_DEPOSIT_AMOUNT);

        vm.prank(depositors[0]);
        listingContract.createListing(address(repoToken1), amount1);

        vm.prank(depositors[1]);
        listingContract.createListing(address(repoToken2), amount2);

        assertEq(listingContract.nextId(), 3);
        assertEq(listingContract.totalListed(address(repoToken1)), amount1);
        assertEq(listingContract.totalListed(address(repoToken2)), amount2);
        assertEq(listingContract.getTotalListings(address(repoToken1)), 1);
        assertEq(listingContract.getTotalListings(address(repoToken2)), 1);
    }

    function testPurchase(uint256 depositAmount, uint256 purchaseAmount) public {
        depositAmount = bound(depositAmount, listingContract.minimumListingAmount(address(purchaseToken)), MAX_DEPOSIT_AMOUNT);
        purchaseAmount = bound(purchaseAmount, 0, MAX_PURCHASE_AMOUNT);

        if (purchaseAmount > depositAmount) {
            purchaseAmount = depositAmount;
        }

        _setAuctionRate(repoToken1, 0.99e18);

        vm.prank(depositors[0]);
        listingContract.createListing(address(repoToken1), depositAmount);

        vm.prank(lenders[0]);
        listingContract.purchase(purchaseAmount, address(repoToken1));
    }

    function testSwapExactPurchaseForRepo(uint256 depositAmount, uint256 purchaseTokenAmount) public {
        _setAuctionRate(repoToken1, 0.99e18);

        (uint256 redemptionTimestamp, , ,) = repoToken1.config();
        uint256 timeToMaturity = redemptionTimestamp > block.timestamp ? redemptionTimestamp - block.timestamp : 0;
        uint8 repoTokenDecimals = ERC20(address(repoToken1)).decimals();

        uint256 numerator = repoToken1.redemptionValue() * listingContract.RATE_PRECISION() * listingContract.THREESIXTY_DAYCOUNT_SECONDS();
        uint256 denominator = listingContract.RATE_PRECISION() * listingContract.THREESIXTY_DAYCOUNT_SECONDS() + ((discountRateAdapter.getDiscountRate(address(repoToken1)) - listingContract.discountRateMarkup()) * timeToMaturity);
        uint256 pricePerToken = (numerator / denominator);

        depositAmount = bound(depositAmount, listingContract.minimumListingAmount(address(purchaseToken)), MAX_DEPOSIT_AMOUNT);
        purchaseTokenAmount = bound(purchaseTokenAmount, 0, MAX_PURCHASE_AMOUNT * pricePerToken * purchaseToken.decimals() / ( listingContract.REDEMPTION_VALUE_PRECISION() * repoTokenDecimals));

        uint256 purchaseAmount = purchaseTokenAmount * listingContract.REDEMPTION_VALUE_PRECISION() * repoTokenDecimals / (pricePerToken * purchaseToken.decimals());

        if (purchaseAmount > depositAmount) {
            purchaseTokenAmount = depositAmount * pricePerToken * purchaseToken.decimals() / (listingContract.REDEMPTION_VALUE_PRECISION() * repoTokenDecimals);
        }


        vm.prank(depositors[0]);
        listingContract.createListing(address(repoToken1), depositAmount);

        vm.prank(lenders[0]);
        listingContract.swapExactPurchaseForRepo(purchaseTokenAmount, address(repoToken1));
    }

    function testAdminFunctions() public {
        // blacklist
        assertEq(listingContract.repoTokenBlacklist(address(repoToken1)), false);

        vm.prank(depositors[0]);
        vm.expectRevert(abi.encodeWithSelector(
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            0x43c183126d60d36Af2e806a42A34A39cfe0C2Af7,
            0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775
        ));
        listingContract.setRepoTokenBlacklist(address(repoToken1), true);

        vm.prank(adminWallet);
        listingContract.setRepoTokenBlacklist(address(repoToken1), true);

        assertEq(listingContract.repoTokenBlacklist(address(repoToken1)), true);
    }
}

