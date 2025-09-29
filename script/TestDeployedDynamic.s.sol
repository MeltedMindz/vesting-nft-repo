// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/Vesting721Of721PlusDynamic.sol";

/**
 * @title TestDeployedDynamicScript
 * @dev Test the deployed Vesting721Of721PlusDynamic contract
 */
contract TestDeployedDynamicScript is Script {
    function run() external view {
        // Deployed contract address
        Vesting721Of721PlusDynamic vesting = Vesting721Of721PlusDynamic(0xceAbAA1d992681A7A4F0923Ff21d3Cc1B5201688);
        
        console.log("=== Testing Deployed Vesting721Of721PlusDynamic Contract ===");
        console.log("Contract Address: 0xceAbAA1d992681A7A4F0923Ff21d3Cc1B5201688");
        console.log("Contract Owner:", vesting.owner());
        console.log("Name:", vesting.name());
        console.log("Symbol:", vesting.symbol());
        console.log("Use Onchain Metadata:", vesting.useOnchainMetadata());
        console.log("Metadata Update Interval:", vesting.metadataUpdateInterval(), "blocks");
        console.log("Base Token URI:", vesting.baseTokenURI());
        console.log("");
        
        // Test linear templates
        console.log("=== Linear Templates ===");
        for (uint256 i = 1; i <= 4; i++) {
            (uint256 cliff, uint256 duration, uint256 slice) = vesting.linearTemplates(i);
            console.log("Template", i, ":");
            console.log("  Cliff:", cliff / 1 days, "days");
            console.log("  Duration:", duration / 1 days, "days");
            console.log("  Slice:", slice / 1 days, "days");
        }
        
        console.log("");
        console.log("=== Contract Status ===");
        console.log("Current Block:", block.number);
        console.log("Contract is ready for use!");
        console.log("");
        console.log("=== Next Steps ===");
        console.log("1. Verify contract on BaseScan using the verification script");
        console.log("2. Update frontend to use new contract address");
        console.log("3. Test creating vesting plans with dynamic metadata");
    }
}
