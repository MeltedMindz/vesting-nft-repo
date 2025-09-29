// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/Vesting721Of721PlusDynamic.sol";

/**
 * @title DeployDynamicScript
 * @dev Deploy the enhanced Vesting721Of721Plus contract with dynamic metadata
 */
contract DeployDynamicScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying Vesting721Of721PlusDynamic with account:", deployer);
        console.log("Account balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the enhanced contract with dynamic metadata
        Vesting721Of721PlusDynamic vesting = new Vesting721Of721PlusDynamic(
            "Vesting NFT Positions", // name
            "VEST",                  // symbol
            "https://vesting-nft.app/metadata/", // base URI
            true                     // use onchain metadata
        );

        console.log("Vesting721Of721PlusDynamic deployed at:", address(vesting));
        console.log("Contract owner:", vesting.owner());
        console.log("Use onchain metadata:", vesting.useOnchainMetadata());
        console.log("Metadata update interval:", vesting.metadataUpdateInterval());

        // Set metadata update interval to update every 50 blocks (more frequent updates)
        vesting.setMetadataUpdateInterval(50);
        console.log("Set metadata update interval to 50 blocks");

        vm.stopBroadcast();
    }
}
