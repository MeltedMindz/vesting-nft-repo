// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Vesting721Of721Plus.sol";
import "../src/mocks/MockERC721.sol";

/**
 * @title VestingTrancheTest
 * @dev Test tranche vesting functionality
 */
contract VestingTrancheTest is Test {
    Vesting721Of721Plus public vesting;
    MockERC721 public mockNFT;

    address public owner = address(0x1);
    address public beneficiary = address(0x2);
    address public issuer = address(0x3);

    function setUp() public {
        vm.startPrank(owner);
        vesting = new Vesting721Of721Plus("Vesting Positions", "VEST", "https://api.example.com/metadata/");
        mockNFT = new MockERC721("Test NFT", "TNFT");
        vm.stopPrank();
    }

    function testCreateTranchePlan() public {
        // Create tranche schedule
        Vesting721Of721Plus.Tranche[] memory tranches = new Vesting721Of721Plus.Tranche[](3);
        tranches[0] = Vesting721Of721Plus.Tranche(block.timestamp + 30 days, 2); // 2 tokens after 30 days
        tranches[1] = Vesting721Of721Plus.Tranche(block.timestamp + 60 days, 5); // 5 tokens after 60 days
        tranches[2] = Vesting721Of721Plus.Tranche(block.timestamp + 90 days, 10); // 10 tokens after 90 days

        // Mint NFTs
        vm.startPrank(issuer);
        uint256[] memory tokenIds = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            tokenIds[i] = mockNFT.mint(issuer);
        }

        Vesting721Of721Plus.PermitInput[] memory permits = new Vesting721Of721Plus.PermitInput[](10);
        for (uint256 i = 0; i < 10; i++) {
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
            address(mockNFT),
            tokenIds,
            tranches,
            permits
        );
        vm.stopPrank();

        // Check position was created
        assertEq(vesting.ownerOf(positionId), beneficiary);
        
        Vesting721Of721Plus.VestingPlan memory plan = vesting.getPlan(positionId);
        assertEq(plan.beneficiary, beneficiary);
        assertEq(plan.sourceCollection, address(mockNFT));
        assertEq(plan.totalCount, 10);
        assertEq(plan.claimedCount, 0);
        assertFalse(plan.isLinear);
        assertFalse(plan.revoked);
    }

    function testTrancheUnlocking() public {
        // Create tranche schedule
        Vesting721Of721Plus.Tranche[] memory tranches = new Vesting721Of721Plus.Tranche[](3);
        tranches[0] = Vesting721Of721Plus.Tranche(block.timestamp + 30 days, 2);
        tranches[1] = Vesting721Of721Plus.Tranche(block.timestamp + 60 days, 5);
        tranches[2] = Vesting721Of721Plus.Tranche(block.timestamp + 90 days, 10);

        // Create plan
        vm.startPrank(issuer);
        uint256[] memory tokenIds = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            tokenIds[i] = mockNFT.mint(issuer);
        }

        Vesting721Of721Plus.PermitInput[] memory permits = new Vesting721Of721Plus.PermitInput[](10);
        for (uint256 i = 0; i < 10; i++) {
            permits[i] = Vesting721Of721Plus.PermitInput({
                tokenId: tokenIds[i],
                deadline: 0,
                signature: "",
                usePermit: false
            });
        }

        uint256 positionId = vesting.createTranchePlan(
            beneficiary,
            address(mockNFT),
            tokenIds,
            tranches,
            permits
        );
        vm.stopPrank();

        // Before first tranche - nothing unlocked
        assertEq(vesting.unlockedCount(positionId, block.timestamp), 0);
        assertEq(vesting.claimableCount(positionId), 0);

        // At first tranche - 2 tokens unlocked
        vm.warp(block.timestamp + 30 days);
        assertEq(vesting.unlockedCount(positionId, block.timestamp), 2);
        assertEq(vesting.claimableCount(positionId), 2);

        // At second tranche - 5 tokens unlocked
        vm.warp(block.timestamp + 30 days); // 60 days total
        assertEq(vesting.unlockedCount(positionId, block.timestamp), 5);
        assertEq(vesting.claimableCount(positionId), 5);

        // At third tranche - all 10 tokens unlocked
        vm.warp(block.timestamp + 30 days); // 90 days total
        assertEq(vesting.unlockedCount(positionId, block.timestamp), 10);
        assertEq(vesting.claimableCount(positionId), 10);
    }

    function testTrancheBoundaryBehavior() public {
        // Create tranche schedule with exact timestamps
        Vesting721Of721Plus.Tranche[] memory tranches = new Vesting721Of721Plus.Tranche[](2);
        uint256 trancheTime = block.timestamp + 30 days;
        tranches[0] = Vesting721Of721Plus.Tranche(trancheTime, 3);
        tranches[1] = Vesting721Of721Plus.Tranche(trancheTime + 1, 5);

        // Create plan
        vm.startPrank(issuer);
        uint256[] memory tokenIds = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            tokenIds[i] = mockNFT.mint(issuer);
        }

        Vesting721Of721Plus.PermitInput[] memory permits = new Vesting721Of721Plus.PermitInput[](5);
        for (uint256 i = 0; i < 5; i++) {
            permits[i] = Vesting721Of721Plus.PermitInput({
                tokenId: tokenIds[i],
                deadline: 0,
                signature: "",
                usePermit: false
            });
        }

        uint256 positionId = vesting.createTranchePlan(
            beneficiary,
            address(mockNFT),
            tokenIds,
            tranches,
            permits
        );
        vm.stopPrank();

        // Just before first tranche
        vm.warp(trancheTime - 1);
        assertEq(vesting.unlockedCount(positionId, block.timestamp), 0);

        // Exactly at first tranche
        vm.warp(trancheTime);
        assertEq(vesting.unlockedCount(positionId, block.timestamp), 3);

        // Just after first tranche
        vm.warp(trancheTime + 1);
        assertEq(vesting.unlockedCount(positionId, block.timestamp), 5);
    }

    function testTrancheClaiming() public {
        // Create tranche schedule
        Vesting721Of721Plus.Tranche[] memory tranches = new Vesting721Of721Plus.Tranche[](2);
        tranches[0] = Vesting721Of721Plus.Tranche(block.timestamp + 30 days, 3);
        tranches[1] = Vesting721Of721Plus.Tranche(block.timestamp + 60 days, 6);

        // Create plan
        vm.startPrank(issuer);
        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) {
            tokenIds[i] = mockNFT.mint(issuer);
        }

        Vesting721Of721Plus.PermitInput[] memory permits = new Vesting721Of721Plus.PermitInput[](6);
        for (uint256 i = 0; i < 6; i++) {
            permits[i] = Vesting721Of721Plus.PermitInput({
                tokenId: tokenIds[i],
                deadline: 0,
                signature: "",
                usePermit: false
            });
        }

        uint256 positionId = vesting.createTranchePlan(
            beneficiary,
            address(mockNFT),
            tokenIds,
            tranches,
            permits
        );
        vm.stopPrank();

        // Fast forward to first tranche
        vm.warp(block.timestamp + 30 days);

        // Claim some tokens
        vm.startPrank(beneficiary);
        uint256[] memory claimableIds = vesting.previewClaimableIds(positionId, 2);
        assertEq(claimableIds.length, 2);

        vesting.claim(positionId, beneficiary, claimableIds);
        vm.stopPrank();

        // Check tokens were transferred
        for (uint256 i = 0; i < claimableIds.length; i++) {
            assertEq(mockNFT.ownerOf(claimableIds[i]), beneficiary);
        }

        // Check claimed count
        Vesting721Of721Plus.VestingPlan memory plan = vesting.getPlan(positionId);
        assertEq(plan.claimedCount, 2);

        // Fast forward to second tranche
        vm.warp(block.timestamp + 30 days);

        // Claim remaining tokens
        vm.startPrank(beneficiary);
        uint256[] memory remainingIds = vesting.previewClaimableIds(positionId, 10);
        assertTrue(remainingIds.length >= 4); // Should have at least 4 more

        vesting.claim(positionId, beneficiary, remainingIds);
        vm.stopPrank();
    }

    function testInvalidTrancheSchedule() public {
        // Test decreasing counts
        Vesting721Of721Plus.Tranche[] memory invalidTranches = new Vesting721Of721Plus.Tranche[](2);
        invalidTranches[0] = Vesting721Of721Plus.Tranche(block.timestamp + 30 days, 5);
        invalidTranches[1] = Vesting721Of721Plus.Tranche(block.timestamp + 60 days, 3); // Decreasing!

        vm.startPrank(issuer);
        uint256[] memory tokenIds = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            tokenIds[i] = mockNFT.mint(issuer);
        }

        Vesting721Of721Plus.PermitInput[] memory permits = new Vesting721Of721Plus.PermitInput[](5);
        for (uint256 i = 0; i < 5; i++) {
            permits[i] = Vesting721Of721Plus.PermitInput({
                tokenId: tokenIds[i],
                deadline: 0,
                signature: "",
                usePermit: false
            });
        }

        vm.expectRevert("Counts must be non-decreasing");
        vesting.createTranchePlan(
            beneficiary,
            address(mockNFT),
            tokenIds,
            invalidTranches,
            permits
        );
        vm.stopPrank();
    }

    function testTrancheFinalUnlock() public {
        // Create plan where final tranche equals total
        Vesting721Of721Plus.Tranche[] memory tranches = new Vesting721Of721Plus.Tranche[](1);
        tranches[0] = Vesting721Of721Plus.Tranche(block.timestamp + 30 days, 5);

        vm.startPrank(issuer);
        uint256[] memory tokenIds = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            tokenIds[i] = mockNFT.mint(issuer);
        }

        Vesting721Of721Plus.PermitInput[] memory permits = new Vesting721Of721Plus.PermitInput[](5);
        for (uint256 i = 0; i < 5; i++) {
            permits[i] = Vesting721Of721Plus.PermitInput({
                tokenId: tokenIds[i],
                deadline: 0,
                signature: "",
                usePermit: false
            });
        }

        uint256 positionId = vesting.createTranchePlan(
            beneficiary,
            address(mockNFT),
            tokenIds,
            tranches,
            permits
        );
        vm.stopPrank();

        // Fast forward to unlock
        vm.warp(block.timestamp + 30 days);
        assertEq(vesting.unlockedCount(positionId, block.timestamp), 5);
        assertEq(vesting.claimableCount(positionId), 5);
    }
}
