# TermFinance Listing Contract

Term Finance is a noncustodial fixed-rate liquidity protocol modeled on tri-party repo arrangements common in traditional finance. Liquidity suppliers and takers are matched through a unique weekly auction process where liquidity takers submit bids and suppliers submit offers to the protocol, which then determines an interest rate that clears the market. Lenders (offerors) asking less than the clearing rate, are assigned a loan and receive ERC-20 receipt tokens ("repo tokens") that represent their claim to repayment on or after maturity. 

## Term Listing Contract Class

The Term Listing Class is a class of smart contracts that enable holders of repo tokens to swap their tokens in a trustless and decentralized manner. 

### RepoTokenLinkedList.sol 

Token holders can create listings to sell their repo tokens. Each listing includes details like the seller's address, token address, and amount. Listings are organized in a linked list structure for efficient management. Users can purchase repo tokens from available listings on a first-come first-serve basis. The contract calculates the price based on a discount rate and each repo tokens' remaining time to maturity. Purchases can be partial or complete, depending on availability. 

### RepoTokenLinkedListEventEmitter.sol

Smart contract paired with RepoTokenLinkedList that emits events for creations and cancellations of new Term Repo Token listings, as well as Term Repo Token purchases. A subgraph listens to and handles these events.

## Development

These contracts were developed using Foundry. Setup your developer environment with the following steps. 

```
curl -L https://foundry.paradigm.xyz | bash

foundryup
```

## Libs

```
forge install OpenZeppelin/openzeppelin-contracts
```

## Build

```
forge build
```

## Test

```
forge test (all tests)
forge test --match-test testDeposit (specific test)
forge test --match-path test/TestListingContract.sol (all tests in file)
forge test -vv (logging)
forge test -vvvv (tracing)
```
