// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/mocks/MockERC721.sol";

/**
 * @title TransferTestNFTsScript
 * @dev Transfer test NFTs to user wallet for testing
 */
contract TransferTestNFTsScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address userWallet = vm.envOr("USER_WALLET", deployer); // Default to deployer if not set
        
        console.log("Transferring test NFTs with the account:", deployer);
        console.log("User wallet:", userWallet);
        console.log("Account balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Get the test NFT contract (deployed earlier)
        MockERC721 testNFT = MockERC721(0x8092D5f24E3da6C50F93B70dAf6A549061b127F3);
        
        // Transfer first 10 NFTs to user wallet
        console.log("Transferring first 10 NFTs to user wallet...");
        for (uint256 i = 1; i <= 10; i++) {
            testNFT.transferFrom(deployer, userWallet, i);
            console.log("Transferred token ID:", i);
        }

        console.log("Total supply:", testNFT.totalSupply());
        console.log("User balance:", testNFT.balanceOf(userWallet));
        console.log("All 10 NFTs transferred successfully!");

        vm.stopBroadcast();
    }
}
