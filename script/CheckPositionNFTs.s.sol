// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/Vesting721Of721Plus.sol";

/**
 * @title CheckPositionNFTsScript
 * @dev Check position NFT ownership and details
 */
contract CheckPositionNFTsScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address userWallet = vm.envOr("USER_WALLET", deployer);
        
        console.log("Checking position NFTs with account:", deployer);
        console.log("User wallet:", userWallet);

        // Check vesting contract
        Vesting721Of721Plus vesting = Vesting721Of721Plus(0xe07547e2F31F5Ea2aaeD04586DB6562c17c35d5a);
        
        console.log("\n=== CHECKING POSITION NFT OWNERSHIP ===");
        console.log("User wallet:", userWallet);
        
        // Check if user owns any position NFTs
        uint256 userBalance = vesting.balanceOf(userWallet);
        console.log("User position NFT balance:", userBalance);
        
        if (userBalance > 0) {
            console.log("\n=== POSITION NFT DETAILS ===");
            // Note: tokenOfOwnerByIndex is not directly exposed by this contract
            // We would need to iterate through position IDs and check ownership
            console.log("  User owns", userBalance, "position NFTs");
            console.log("  Note: tokenOfOwnerByIndex is not directly exposed by this contract");
        } else {
            console.log("User does not own any position NFTs");
        }
        
        // Note: totalSupply is not directly exposed by this contract
        console.log("\nNote: totalSupply is not directly exposed by this contract");
    }
}
