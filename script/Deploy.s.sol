// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/Vesting721Of721Plus.sol";

/**
 * @title DeployScript
 * @dev Deploy Vesting721Of721Plus contract
 */
contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts with the account:", deployer);
        console.log("Account balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Vesting721Of721Plus
        Vesting721Of721Plus vesting = new Vesting721Of721Plus(
            "Vesting Positions",
            "VEST",
            "https://api.vesting.com/metadata/"
        );

        console.log("Vesting721Of721Plus deployed at:", address(vesting));

        vm.stopBroadcast();

        // Verify contract on Base if on mainnet
        if (block.chainid == 8453) {
            console.log("Verifying contract on Base mainnet...");
            // Verification would be handled by foundry.toml configuration
        } else if (block.chainid == 84532) {
            console.log("Verifying contract on Base Sepolia...");
            // Verification would be handled by foundry.toml configuration
        }
    }
}
