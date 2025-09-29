// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/Vesting721Of721PlusDynamic.sol";
import "../src/mocks/MockERC721.sol";

/**
 * @title TestDynamicMetadataScript
 * @dev Test the dynamic metadata functionality
 */
contract TestDynamicMetadataScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Testing dynamic metadata with account:", deployer);

        // Use the deployed contract address
        Vesting721Of721PlusDynamic vesting = Vesting721Of721PlusDynamic(0x0000000000000000000000000000000000000000); // Replace with actual address
        
        // Use the deployed test NFT contract (commented out to avoid unused variable warning)
        // MockERC721 testNFT = MockERC721(0x8092D5f24E3da6C50F93B70dAf6A549061b127F3);

        vm.startBroadcast(deployerPrivateKey);

        // Test metadata generation
        console.log("\n=== Testing Dynamic Metadata ===");
        
        // Check if we have any positions
        uint256 balance = vesting.balanceOf(deployer);
        console.log("User has", balance, "vesting positions");
        
        if (balance > 0) {
            // Test metadata for first position
            uint256 positionId = 1; // Assuming position 1 exists
            
            try vesting.tokenURI(positionId) returns (string memory uri) {
                console.log("Position", positionId, "metadata URI:", uri);
                
                // Decode and show metadata content
                if (bytes(uri).length > 0 && keccak256(bytes(uri)) == keccak256(bytes("data:application/json;base64,"))) {
                    console.log("Metadata is Base64 encoded on-chain metadata");
                } else {
                    console.log("Metadata is external URI");
                }
            } catch {
                console.log("Error fetching metadata for position", positionId);
            }
        } else {
            console.log("No positions found to test metadata");
        }

        // Test metadata update settings
        console.log("\n=== Metadata Settings ===");
        console.log("Use onchain metadata:", vesting.useOnchainMetadata());
        console.log("Metadata update interval:", vesting.metadataUpdateInterval(), "blocks");
        console.log("Current block number:", block.number);

        vm.stopBroadcast();
    }
}
