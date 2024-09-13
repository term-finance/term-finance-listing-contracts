// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/RepoTokenLinkedList.sol";
import "../src/RepoTokenLinkedListEventEmitter.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployRepoTokenLinkedList is Script {
    function run() external {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");

        // Set up the RPC URL (optional if you're using the default foundry config)
        string memory rpcUrl = vm.envString("RPC_URL");

        vm.startBroadcast(deployerPK);

        // Retrieve environment variables
        address controlAddress = vm.envAddress("CONTROLLER_ADDRESS");
        address discountRateAdapterAddress = vm.envAddress("DISCOUNT_RATE_ADAPTER_ADDRESS");
        address admin = vm.envAddress("ADMIN_ADDRESS");
        address devops = vm.envAddress("DEVOPS_ADDRESS");

        RepoTokenLinkedListEventEmitter eventEmitterimpl = new RepoTokenLinkedListEventEmitter();

        console.log("deployed event emitter impl contract to");
        console.log(address(eventEmitterimpl));

        // Deploy the Proxy contract
        ERC1967Proxy eventEmitterProxy = new ERC1967Proxy(
            address(eventEmitterimpl),
            abi.encodeWithSelector(RepoTokenLinkedListEventEmitter.initialize.selector, admin, devops)
        );

        RepoTokenLinkedListEventEmitter marketplaceEventEmitter = RepoTokenLinkedListEventEmitter(address(eventEmitterProxy));


        RepoTokenLinkedList impl = new RepoTokenLinkedList(controlAddress, address(marketplaceEventEmitter));

        console.log("deployed impl contract to");
        console.log(address(impl));

        // Deploy the Proxy contract
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeWithSelector(RepoTokenLinkedList.initialize.selector, discountRateAdapterAddress, admin, devops)
        );

        RepoTokenLinkedList listingContract = RepoTokenLinkedList(address(proxy));
        console.log("deployed proxy to");
        console.log(address(proxy));
        
        vm.stopBroadcast();
    }
}
