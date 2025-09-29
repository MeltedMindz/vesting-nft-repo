// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @title VerifyDynamicScript
 * @dev Script to verify the deployed Vesting721Of721PlusDynamic contract
 */
contract VerifyDynamicScript is Script {
    function run() external {
        console.log("=== Contract Verification Information ===");
        console.log("Contract Address: 0xceAbAA1d992681A7A4F0923Ff21d3Cc1B5201688");
        console.log("Network: Base Mainnet");
        console.log("Contract Name: Vesting721Of721PlusDynamic");
        console.log("Source File: src/Vesting721Of721PlusDynamic.sol");
        console.log("Compiler Version: 0.8.24");
        console.log("Optimization: 20000 runs");
        console.log("");
        console.log("=== Constructor Arguments ===");
        console.log("Name: 'Vesting NFT Positions Dynamic'");
        console.log("Symbol: 'VESTD'");
        console.log("Base URI: 'https://vesting-nft.app/metadata/'");
        console.log("Use Onchain Metadata: true");
        console.log("");
        console.log("=== Verification Command ===");
        console.log("Run this command to verify the contract:");
        console.log("");
        console.log("forge verify-contract \\");
        console.log("  --chain-id 8453 \\");
        console.log("  --num-of-optimizations 20000 \\");
        console.log("  --watch \\");
        console.log("  --etherscan-api-key YOUR_BASESCAN_API_KEY \\");
        console.log("  0xceAbAA1d992681A7A4F0923Ff21d3Cc1B5201688 \\");
        console.log("  src/Vesting721Of721PlusDynamic.sol:Vesting721Of721PlusDynamic \\");
        console.log("  --constructor-args \\");
        console.log("  $(cast abi-encode 'constructor(string,string,string,bool)' \\");
        console.log("    'Vesting NFT Positions Dynamic' \\");
        console.log("    'VESTD' \\");
        console.log("    'https://vesting-nft.app/metadata/' \\");
        console.log("    true)");
        console.log("");
        console.log("=== Alternative: Use BaseScan Web Interface ===");
        console.log("1. Go to https://basescan.org/address/0xceAbAA1d992681A7A4F0923Ff21d3Cc1B5201688");
        console.log("2. Click 'Contract' tab");
        console.log("3. Click 'Verify and Publish'");
        console.log("4. Select 'Solidity (Single file)'");
        console.log("5. Compiler Version: 0.8.24");
        console.log("6. License: MIT");
        console.log("7. Optimization: Yes (20000 runs)");
        console.log("8. Paste the contract source code");
        console.log("9. Constructor arguments (ABI encoded):");
        console.log("   000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000001d56657374696e67204e465420506f736974696f6e732044796e616d696300000000000000000000000000000000000000000000000000000000000000000000055645535444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002168747470733a2f2f76657374696e672d6e66742e6170702f6d657461646174612f00000000000000000000000000000000000000000000000000000000000000");
    }
}
