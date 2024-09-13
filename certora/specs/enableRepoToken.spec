using DummyERC20A as enableRepoTokenRepoToken;

methods {
    // TODO: Summarize call to TermRepoServicer so we don't have to import that full contract.
}

rule enableRepoTokenStoresEchangeRate(
    env e,
    address repoServicer,
    uint256 rate
) {
    mathint rateBefore = discountRates(enableRepoTokenRepoToken, repoServicer);
    enableRepoToken(e, enableRepoTokenRepoToken, repoServicer, rate);
    mathint rateAfter = discountRates(enableRepoTokenRepoToken, repoServicer);

    // TODO:
    assert true;
}
