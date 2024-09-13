// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "forge-std/Test.sol";
import {RepoTokenLinkedList} from "../src/RepoTokenLinkedList.sol";
import {TermDiscountRateAdapter} from "../src/TermDiscountRateAdapter.sol";
import {RepoTokenLinkedListEventEmitter} from "../src/RepoTokenLinkedListEventEmitter.sol";

import {IRepoTokenLinkedListEvents} from "../src/interface/IRepoTokenLinkedListEvents.sol";
import {ITermController} from "../src/interface/ITermController.sol";
import {ITermRepoToken} from "../src/interface/ITermRepoToken.sol";
import {MockTermRepoToken} from "./MockTermRepoToken.sol";
import {MockTermController} from "./MockTermController.sol";
import {MockERC20} from "./MockERC20.sol";

contract TermListingTestBase is Test, IRepoTokenLinkedListEvents {
    uint256 public constant NUM_DEPOSITORS = 10;
    uint256 public constant NUM_LENDERS = 10;
    uint256 public constant DELTA = 0.0001e18;
    uint256 public constant MIN_DEPOSIT_AMOUNT = 100000;
    uint256 public constant MAX_DEPOSIT_AMOUNT = 1000e18;
    uint256 public constant MAX_PURCHASE_AMOUNT = 1000e18;

    MockTermController termController;
    TermDiscountRateAdapter discountRateAdapter;
    RepoTokenLinkedList listingContractImpl;
    RepoTokenLinkedList listingContract;
    RepoTokenLinkedListEventEmitter eventEmitterImpl;
    RepoTokenLinkedListEventEmitter eventEmitter;
    ERC20 purchaseToken;
    ITermRepoToken repoToken1;
    ITermRepoToken repoToken2;
    address[] depositors;
    address[] lenders;
    address testOwner;
    address devOpsWallet;
    address adminWallet;

    function setUp() public virtual {
        depositors = new address[](NUM_DEPOSITORS);
        lenders = new address[](NUM_LENDERS);

        for (uint256 i; i < NUM_DEPOSITORS; i++) {
            depositors[i] = vm.addr(0x1000000 + i);
        }
        for (uint256 i; i < NUM_LENDERS; i++) {
            lenders[i] = vm.addr(0x2000000 + i);
        }
        testOwner = vm.addr(0x67890);
        devOpsWallet = vm.addr(0x11111);
        adminWallet = vm.addr(0x22222);

        purchaseToken = new MockERC20("TestPurchaseToken", "PURCHASE");
        repoToken1 = new MockTermRepoToken(address(purchaseToken), block.timestamp + 1 weeks, bytes32("test repo token 1"));
        repoToken2 = new MockTermRepoToken(address(purchaseToken), block.timestamp + 4 weeks, bytes32("test repo token 2"));
        termController = new MockTermController();

        eventEmitterImpl = new RepoTokenLinkedListEventEmitter();
        discountRateAdapter = new TermDiscountRateAdapter(address(termController), adminWallet);

        bytes memory initData = abi.encodeWithSelector(eventEmitterImpl.initialize.selector, adminWallet, devOpsWallet);
        ERC1967Proxy proxy = new ERC1967Proxy(address(eventEmitterImpl), initData);
        eventEmitter = RepoTokenLinkedListEventEmitter(address(proxy));

        listingContractImpl = new RepoTokenLinkedList(
            address(termController),
            address(eventEmitter)
        );

        initData = abi.encodeWithSelector(
            listingContractImpl.initialize.selector, 
            address(discountRateAdapter),
            adminWallet,
            devOpsWallet
        );
        proxy = new ERC1967Proxy(address(listingContractImpl), initData);
        listingContract = RepoTokenLinkedList(address(proxy));

        vm.prank(adminWallet);
        eventEmitter.pairListingContract(address(listingContract));

        vm.prank(adminWallet);
        listingContract.manageMinimumListing(address(purchaseToken), MIN_DEPOSIT_AMOUNT);

        _fundTestAccounts();
    }

    function _fundTestAccounts() private {
        for (uint256 i; i < NUM_DEPOSITORS; i++) {
            repoToken1.transfer(depositors[i], MAX_DEPOSIT_AMOUNT);
            vm.prank(depositors[i]);
            repoToken1.approve(address(listingContract), type(uint256).max);

            repoToken2.transfer(depositors[i], MAX_DEPOSIT_AMOUNT);
            vm.prank(depositors[i]);
            repoToken2.approve(address(listingContract), type(uint256).max);
        }
        for (uint256 i; i < NUM_LENDERS; i++) {
            purchaseToken.transfer(lenders[i], MAX_PURCHASE_AMOUNT);
            vm.prank(lenders[i]);
            purchaseToken.approve(address(listingContract), type(uint256).max);
        }
    }

    function _setAuctionRate(ITermRepoToken repoToken, uint256 rate) internal {
        termController.setAuctionRate(repoToken.termRepoId(), rate);
    }
}