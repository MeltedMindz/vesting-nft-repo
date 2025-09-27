// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/Vesting721Of721Plus.sol";

/**
 * @title RevokeAutoScript
 * @dev Auto-revoke a vesting plan
 */
contract RevokeAutoScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get contract addresses from environment
        address vestingAddress = vm.envOr("VESTING_ADDRESS", address(0));
        uint256 positionId = vm.envOr("POSITION_ID", uint256(0));
        
        require(vestingAddress != address(0), "VESTING_ADDRESS not set");
        require(positionId != 0, "POSITION_ID not set");
        
        Vesting721Of721Plus vesting = Vesting721Of721Plus(vestingAddress);
        
        console.log("Auto-revoking position:");
        console.log("Vesting contract:", vestingAddress);
        console.log("Position ID:", positionId);
        console.log("Account:", deployer);

        // Get plan details before revocation
        Vesting721Of721Plus.VestingPlan memory plan = vesting.getPlan(positionId);
        console.log("Plan details before revocation:");
        console.log("  Beneficiary:", plan.beneficiary);
        console.log("  Issuer:", plan.issuer);
        console.log("  Total count:", plan.totalCount);
        console.log("  Claimed count:", plan.claimedCount);
        console.log("  Revoked:", plan.revoked);
        
        // Check unlocked count
        uint256 unlocked = vesting.unlockedCount(positionId, block.timestamp);
        console.log("  Unlocked count:", unlocked);
        
        // Check claimable count
        uint256 claimable = vesting.claimableCount(positionId);
        console.log("  Claimable count:", claimable);

        vm.startBroadcast(deployerPrivateKey);

        // Auto-revoke the plan
        vesting.revokeAuto(positionId);

        vm.stopBroadcast();

        console.log("Position auto-revoked successfully!");
        
        // Get plan details after revocation
        Vesting721Of721Plus.VestingPlan memory revokedPlan = vesting.getPlan(positionId);
        console.log("Plan details after revocation:");
        console.log("  Revoked:", revokedPlan.revoked);
        console.log("  Revoke time:", revokedPlan.revokeTime);
        console.log("  Vested cap on revoke:", revokedPlan.vestedCapOnRevoke);
        
        // Check remaining claimable count
        uint256 remainingClaimable = vesting.claimableCount(positionId);
        console.log("  Remaining claimable count:", remainingClaimable);
    }
}
