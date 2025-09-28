// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/mocks/MockERC721.sol";

/**
 * @title MintTestNFTsScript
 * @dev Mint 100 test NFTs for vesting contract testing
 */
contract MintTestNFTsScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Minting test NFTs with the account:", deployer);
        console.log("Account balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy MockERC721 contract
        MockERC721 testNFT = new MockERC721("Test Vesting NFTs", "TVNFT");
        console.log("Test NFT contract deployed at:", address(testNFT));

        // Mint 100 NFTs
        console.log("Minting 100 test NFTs...");
        for (uint256 i = 1; i <= 100; i++) {
            uint256 tokenId = testNFT.mint(deployer);
            if (i % 10 == 0) {
                console.log("Minted token ID:", tokenId);
            }
        }

        console.log("Total supply:", testNFT.totalSupply());
        console.log("All 100 NFTs minted successfully!");

        vm.stopBroadcast();
    }
}
