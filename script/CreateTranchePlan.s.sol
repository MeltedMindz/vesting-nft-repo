// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/Vesting721Of721Plus.sol";
import "../src/mocks/MockERC721.sol";

/**
 * @title CreateTranchePlanScript
 * @dev Create a tranche vesting plan
 */
contract CreateTranchePlanScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get contract addresses from environment
        address vestingAddress = vm.envOr("VESTING_ADDRESS", address(0));
        address sourceCollection = vm.envOr("SOURCE_COLLECTION", address(0));
        address beneficiary = vm.envOr("BENEFICIARY", address(0));
        
        require(vestingAddress != address(0), "VESTING_ADDRESS not set");
        require(sourceCollection != address(0), "SOURCE_COLLECTION not set");
        require(beneficiary != address(0), "BENEFICIARY not set");
        
        Vesting721Of721Plus vesting = Vesting721Of721Plus(vestingAddress);
        MockERC721 sourceNFT = MockERC721(sourceCollection);
        
        console.log("Creating tranche plan:");
        console.log("Vesting contract:", vestingAddress);
        console.log("Source collection:", sourceCollection);
        console.log("Beneficiary:", beneficiary);
        console.log("Account:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Mint some NFTs for the plan
        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) {
            tokenIds[i] = sourceNFT.mint(deployer);
            console.log("Minted token ID:", tokenIds[i]);
        }

        // Create tranche schedule
        Vesting721Of721Plus.Tranche[] memory tranches = new Vesting721Of721Plus.Tranche[](3);
        tranches[0] = Vesting721Of721Plus.Tranche(block.timestamp + 30 days, 2);  // 2 tokens after 30 days
        tranches[1] = Vesting721Of721Plus.Tranche(block.timestamp + 60 days, 4);  // 4 tokens after 60 days
        tranches[2] = Vesting721Of721Plus.Tranche(block.timestamp + 90 days, 6);  // 6 tokens after 90 days

        console.log("Tranche schedule:");
        for (uint256 i = 0; i < tranches.length; i++) {
            console.log("  Tranche", i, ": timestamp =", tranches[i].timestamp, ", count =", tranches[i].count);
        }

        // Create permit inputs (no permits for this example)
        Vesting721Of721Plus.PermitInput[] memory permits = new Vesting721Of721Plus.PermitInput[](6);
        for (uint256 i = 0; i < 6; i++) {
            permits[i] = Vesting721Of721Plus.PermitInput({
                tokenId: tokenIds[i],
                deadline: 0,
                signature: "",
                usePermit: false
            });
        }

        // Create tranche plan
        uint256 positionId = vesting.createTranchePlan(
            beneficiary,
            sourceCollection,
            tokenIds,
            tranches,
            permits
        );

        vm.stopBroadcast();

        console.log("Tranche plan created with position ID:", positionId);
        console.log("Position owner:", vesting.ownerOf(positionId));
        
        // Get plan details
        Vesting721Of721Plus.VestingPlan memory plan = vesting.getPlan(positionId);
        console.log("Plan details:");
        console.log("  Beneficiary:", plan.beneficiary);
        console.log("  Source collection:", plan.sourceCollection);
        console.log("  Total count:", plan.totalCount);
        console.log("  Start time:", plan.startTime);
        console.log("  Is linear:", plan.isLinear);
    }
}
