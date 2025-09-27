// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/Vesting721Of721Plus.sol";

/**
 * @title UtilsScript
 * @dev Utility functions for vesting contract
 */
contract UtilsScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get contract addresses from environment
        address vestingAddress = vm.envOr("VESTING_ADDRESS", address(0));
        uint256 positionId = vm.envOr("POSITION_ID", uint256(0));
        
        require(vestingAddress != address(0), "VESTING_ADDRESS not set");
        require(positionId != 0, "POSITION_ID not set");
        
        Vesting721Of721Plus vesting = Vesting721Of721Plus(vestingAddress);
        
        console.log("Vesting contract utilities:");
        console.log("Contract address:", vestingAddress);
        console.log("Position ID:", positionId);
        console.log("Account:", deployer);

        // Get plan details
        Vesting721Of721Plus.VestingPlan memory plan = vesting.getPlan(positionId);
        console.log("\n=== Plan Details ===");
        console.log("Beneficiary:", plan.beneficiary);
        console.log("Source collection:", plan.sourceCollection);
        console.log("Issuer:", plan.issuer);
        console.log("Start time:", plan.startTime);
        console.log("Total count:", plan.totalCount);
        console.log("Claimed count:", plan.claimedCount);
        console.log("Is linear:", plan.isLinear);
        console.log("Revoked:", plan.revoked);
        console.log("Revoke time:", plan.revokeTime);
        console.log("Vested cap on revoke:", plan.vestedCapOnRevoke);

        // Get current status
        uint256 unlocked = vesting.unlockedCount(positionId, block.timestamp);
        uint256 claimable = vesting.claimableCount(positionId);
        uint256 nextUnlock = vesting.nextUnlockTime(positionId);
        
        console.log("\n=== Current Status ===");
        console.log("Current timestamp:", block.timestamp);
        console.log("Unlocked count:", unlocked);
        console.log("Claimable count:", claimable);
        console.log("Next unlock time:", nextUnlock);

        // Preview claimable IDs
        uint256[] memory claimableIds = vesting.previewClaimableIds(positionId, 10);
        console.log("\n=== Preview Claimable IDs ===");
        console.log("Number of claimable IDs:", claimableIds.length);
        for (uint256 i = 0; i < claimableIds.length; i++) {
            console.log("  Claimable ID", i, ":", claimableIds[i]);
        }

        // Get token URI
        string memory tokenURI = vesting.tokenURI(positionId);
        console.log("\n=== Token URI ===");
        console.log("Token URI:", tokenURI);

        // Check if position exists
        try vesting.ownerOf(positionId) returns (address owner) {
            console.log("\n=== Position Owner ===");
            console.log("Position owner:", owner);
        } catch {
            console.log("\n=== Position Status ===");
            console.log("Position does not exist or is invalid");
        }

        // Get contract metadata settings
        console.log("\n=== Contract Settings ===");
        console.log("Base token URI:", vesting.baseTokenURI());
        console.log("Use on-chain metadata:", vesting.useOnchainMetadata());

        // Get template details if linear
        if (plan.isLinear) {
            console.log("\n=== Linear Template ===");
            // Note: In a real implementation, you'd need to store template ID with the plan
            // For now, we'll just show that it's linear
            console.log("Plan type: Linear (template details not stored with plan)");
        } else {
            console.log("\n=== Tranche Schedule ===");
            console.log("Plan type: Tranche");
            // Note: In a real implementation, you'd need to get tranche details
            console.log("Tranche details not accessible from this script");
        }
    }
}
