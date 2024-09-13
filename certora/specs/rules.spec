import "./enableRepoToken.spec";

methods {
    // Envfree methods in TermListingContractHarness

    // Envfree fields in TermListingContract
    function TERM_CONTROLLER() external returns (address) envfree;
    function discountRates(address,address) external returns (uint256) envfree;

    // Envfree methods in TermListingContract
    function getRepoTokenContext(address) external returns (TermListingContractHarness.RepoTokenContext) envfree;
    function getPurchaseTokenContext(address) external returns (TermListingContractHarness.PurchaseTokenContext) envfree;
    function getDepositorRepoTokenContext(address,address) external returns (TermListingContractHarness.DepositorRepoTokenContext) envfree;
    function getDepositorPurchaseTokenContext(address,address) external returns (TermListingContractHarness.DepositorPurchaseTokenContext) envfree;
    function getActualDepositorBalances(address,address) external returns (uint256,uint256) envfree;
    // function lend(address,address,uint256) external envfree;
    function buy(address,uint256) external envfree;
    function deposit(address,uint256,bool) external envfree;
    // TODO: batchWithdrawAndRedeem
    function withdrawAndRedeem(address,address,uint256,bool) external envfree;
    function withdraw(address,uint256,bool) external envfree;
    function claim(address) external envfree;
}

// enableRepoToken.spec
use rule enableRepoTokenStoresEchangeRate;
