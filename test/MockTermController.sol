// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITermController, AuctionMetadata} from "../src/interface/ITermController.sol";

contract MockTermController is ITermController {

    mapping(bytes32 => AuctionMetadata[]) internal auctionResults;

    function isTermDeployed(address contractAddress) external view returns (bool) {
        if (contractAddress == address(0)) return false;
        return true;
    }

    function getTermAuctionResults(bytes32 termRepoId) external view returns (
        AuctionMetadata[] memory auctionMetadata, uint8 numOfAuctions
    ) {
        return (auctionResults[termRepoId], uint8(auctionResults[termRepoId].length));
    }

    function setAuctionRate(bytes32 termRepoId, uint256 rate) external {
        AuctionMetadata memory metadata;

        metadata.auctionClearingRate = rate;

        delete auctionResults[termRepoId];
        auctionResults[termRepoId].push(metadata);
    }
}
