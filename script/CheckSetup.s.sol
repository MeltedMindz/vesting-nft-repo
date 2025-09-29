// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/Vesting721Of721Plus.sol";
import "../src/mocks/MockERC721.sol";

/**
 * @title CheckSetupScript
 * @dev Check contract setup and NFT ownership
 */
contract CheckSetupScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address userWallet = vm.envOr("USER_WALLET", deployer);
        
        console.log("Checking setup with account:", deployer);
        console.log("User wallet:", userWallet);

        // Check vesting contract
        Vesting721Of721Plus vesting = Vesting721Of721Plus(0xe07547e2F31F5Ea2aaeD04586DB6562c17c35d5a);
        
        // Check templates
        console.log("\n=== CHECKING TEMPLATES ===");
        for (uint256 i = 1; i <= 4; i++) {
            (uint256 cliff, uint256 duration, uint256 slice) = vesting.linearTemplates(i);
            console.log("Template", i);
            console.log("  Cliff:", cliff / 1 days, "days");
            console.log("  Duration:", duration / 1 days, "days");
            console.log("  Slice:", slice / 1 days, "days");
        }
        
        // Check test NFT contract
        MockERC721 testNFT = MockERC721(0x8092D5f24E3da6C50F93B70dAf6A549061b127F3);
        
        console.log("\n=== CHECKING NFT OWNERSHIP ===");
        console.log("User wallet:", userWallet);
        console.log("User NFT balance:", testNFT.balanceOf(userWallet));
        
        // Check ownership of specific tokens
        for (uint256 i = 1; i <= 10; i++) {
            address owner = testNFT.ownerOf(i);
            console.log("Token", i, "owner:", owner);
        }
        
        // Check if user owns tokens 1-4 specifically
        console.log("\n=== CHECKING TOKENS 1-4 OWNERSHIP ===");
        console.log("Token 1 owner:", testNFT.ownerOf(1));
        console.log("Token 2 owner:", testNFT.ownerOf(2));
        console.log("Token 3 owner:", testNFT.ownerOf(3));
        console.log("Token 4 owner:", testNFT.ownerOf(4));
    }
}
