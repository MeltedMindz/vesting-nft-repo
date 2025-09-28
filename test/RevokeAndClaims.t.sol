// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Vesting721Of721Plus.sol";
import "../src/mocks/MockERC721.sol";

/**
 * @title RevokeAndClaimsTest
 * @dev Test revocation and claiming functionality
 */
contract RevokeAndClaimsTest is Test {
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

    function testManualRevoke() public {
        // Create linear plan
        vm.startPrank(owner);
        uint256 templateId = vesting.setLinearTemplate(0, 365 days, 1 days); // No cliff, 1 year duration
        vm.stopPrank();

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

        uint256 positionId = vesting.createLinearPlan(
            beneficiary,
            address(mockNFT),
            templateId,
            tokenIds,
            permits
        );
        vm.stopPrank();

        // Fast forward to unlock some tokens
        vm.warp(block.timestamp + 100 days);
        uint256 unlocked = vesting.unlockedCount(positionId, block.timestamp);
        assertTrue(unlocked > 0);

        // Revoke plan
        vm.startPrank(issuer);
        uint256 unvested = 10 - unlocked;
        uint256[] memory returnTokenIds = new uint256[](unvested);
        
        // Get the last unvested tokens (largest IDs)
        for (uint256 i = 0; i < unvested; i++) {
            returnTokenIds[i] = tokenIds[tokenIds.length - 1 - i];
        }

        vesting.revoke(positionId, returnTokenIds);
        vm.stopPrank();

        // Check revocation state
        Vesting721Of721Plus.VestingPlan memory plan = vesting.getPlan(positionId);
        assertTrue(plan.revoked);
        assertEq(plan.revokeTime, block.timestamp);
        assertEq(plan.vestedCapOnRevoke, unlocked);

        // Check returned tokens
        for (uint256 i = 0; i < returnTokenIds.length; i++) {
            assertEq(mockNFT.ownerOf(returnTokenIds[i]), issuer);
        }

        // Beneficiary can still claim up to vested cap
        assertEq(vesting.claimableCount(positionId), unlocked);
    }

    function testAutoRevoke() public {
        // Create linear plan
        vm.startPrank(owner);
        uint256 templateId = vesting.setLinearTemplate(0, 365 days, 1 days);
        vm.stopPrank();

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

        uint256 positionId = vesting.createLinearPlan(
            beneficiary,
            address(mockNFT),
            templateId,
            tokenIds,
            permits
        );
        vm.stopPrank();

        // Fast forward to unlock some tokens
        vm.warp(block.timestamp + 100 days);
        uint256 unlocked = vesting.unlockedCount(positionId, block.timestamp);
        assertTrue(unlocked > 0);

        // Auto-revoke
        vm.startPrank(issuer);
        vesting.revokeAuto(positionId);
        vm.stopPrank();

        // Check revocation state
        Vesting721Of721Plus.VestingPlan memory plan = vesting.getPlan(positionId);
        assertTrue(plan.revoked);
        assertEq(plan.revokeTime, block.timestamp);
        assertEq(plan.vestedCapOnRevoke, unlocked);

        // Check that largest unreleased tokens were returned
        uint256 unvested = 10 - unlocked;
        uint256[] memory expectedReturned = new uint256[](unvested);
        for (uint256 i = 0; i < unvested; i++) {
            expectedReturned[i] = tokenIds[tokenIds.length - 1 - i];
        }

        for (uint256 i = 0; i < expectedReturned.length; i++) {
            assertEq(mockNFT.ownerOf(expectedReturned[i]), issuer);
        }

        // Beneficiary can still claim up to vested cap
        assertEq(vesting.claimableCount(positionId), unlocked);
    }

    function testRevokeAfterPartialClaim() public {
        // Create linear plan
        vm.startPrank(owner);
        uint256 templateId = vesting.setLinearTemplate(0, 365 days, 1 days);
        vm.stopPrank();

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

        uint256 positionId = vesting.createLinearPlan(
            beneficiary,
            address(mockNFT),
            templateId,
            tokenIds,
            permits
        );
        vm.stopPrank();

        // Fast forward and claim some tokens
        vm.warp(block.timestamp + 100 days);
        
        vm.startPrank(beneficiary);
        uint256[] memory claimableIds = vesting.previewClaimableIds(positionId, 3);
        vesting.claim(positionId, beneficiary, claimableIds);
        vm.stopPrank();

        uint256 claimed = claimableIds.length;
        uint256 totalUnlocked = vesting.unlockedCount(positionId, block.timestamp);

        // Revoke
        vm.startPrank(issuer);
        uint256 unvested = 10 - totalUnlocked;
        uint256[] memory returnTokenIds = new uint256[](unvested);
        
        for (uint256 i = 0; i < unvested; i++) {
            returnTokenIds[i] = tokenIds[tokenIds.length - 1 - i];
        }

        vesting.revoke(positionId, returnTokenIds);
        vm.stopPrank();

        // Check that beneficiary can still claim remaining vested tokens
        Vesting721Of721Plus.VestingPlan memory plan = vesting.getPlan(positionId);
        uint256 remainingClaimable = plan.vestedCapOnRevoke - plan.claimedCount;
        assertEq(vesting.claimableCount(positionId), remainingClaimable);
        assertEq(remainingClaimable, totalUnlocked - claimed);
    }

    function testRevokePolicyLargestIds() public {
        // Create plan with specific token IDs
        vm.startPrank(owner);
        uint256 templateId = vesting.setLinearTemplate(0, 365 days, 1 days);
        vm.stopPrank();

        vm.startPrank(issuer);
        uint256[] memory tokenIds = new uint256[](5);
        mockNFT.mintWithId(issuer, 100);
        tokenIds[0] = 100;
        mockNFT.mintWithId(issuer, 200);
        tokenIds[1] = 200;
        mockNFT.mintWithId(issuer, 300);
        tokenIds[2] = 300;
        mockNFT.mintWithId(issuer, 400);
        tokenIds[3] = 400;
        mockNFT.mintWithId(issuer, 500);
        tokenIds[4] = 500;

        Vesting721Of721Plus.PermitInput[] memory permits = new Vesting721Of721Plus.PermitInput[](5);
        for (uint256 i = 0; i < 5; i++) {
            permits[i] = Vesting721Of721Plus.PermitInput({
                tokenId: tokenIds[i],
                deadline: 0,
                signature: "",
                usePermit: false
            });
        }

        uint256 positionId = vesting.createLinearPlan(
            beneficiary,
            address(mockNFT),
            templateId,
            tokenIds,
            permits
        );
        vm.stopPrank();

        // Fast forward to unlock 3 tokens
        vm.warp(block.timestamp + 200 days);
        uint256 unlocked = vesting.unlockedCount(positionId, block.timestamp);
        assertTrue(unlocked >= 3);

        // Auto-revoke
        vm.startPrank(issuer);
        vesting.revokeAuto(positionId);
        vm.stopPrank();

        // Check that largest unreleased tokens (400, 500) were returned to issuer
        // and smallest tokens (100, 200, 300) remain for beneficiary
        assertEq(mockNFT.ownerOf(400), issuer);
        assertEq(mockNFT.ownerOf(500), issuer);
        
        // Beneficiary should be able to claim the smaller tokens
        vm.startPrank(beneficiary);
        uint256[] memory claimableIds = vesting.previewClaimableIds(positionId, 10);
        assertTrue(claimableIds.length >= 3);
        
        // Verify the claimable tokens are the smaller ones
        for (uint256 i = 0; i < claimableIds.length; i++) {
            assertTrue(claimableIds[i] <= 300); // Should be 100, 200, 300
        }
        vm.stopPrank();
    }

    function testRevokeInvalidOperations() public {
        // Create plan
        vm.startPrank(owner);
        uint256 templateId = vesting.setLinearTemplate(0, 365 days, 1 days);
        vm.stopPrank();

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

        uint256 positionId = vesting.createLinearPlan(
            beneficiary,
            address(mockNFT),
            templateId,
            tokenIds,
            permits
        );
        vm.stopPrank();

        // Non-issuer cannot revoke
        vm.startPrank(beneficiary);
        vm.expectRevert("Not issuer");
        vesting.revoke(positionId, new uint256[](1));
        vm.stopPrank();

        // Cannot revoke with wrong count
        vm.startPrank(issuer);
        vm.expectRevert("Wrong return count");
        vesting.revoke(positionId, new uint256[](10)); // Too many
        vm.stopPrank();

        // Cannot revoke twice
        vm.warp(block.timestamp + 100 days);
        uint256 unvested = 5 - vesting.unlockedCount(positionId, block.timestamp);
        uint256[] memory returnTokenIds = new uint256[](unvested);
        for (uint256 i = 0; i < unvested; i++) {
            returnTokenIds[i] = tokenIds[tokenIds.length - 1 - i];
        }

        vesting.revoke(positionId, returnTokenIds);
        
        vm.expectRevert("Already revoked");
        vesting.revoke(positionId, returnTokenIds);
        vm.stopPrank();
    }

    function testRevokeAccounting() public {
        // Create plan
        vm.startPrank(owner);
        uint256 templateId = vesting.setLinearTemplate(0, 365 days, 1 days);
        vm.stopPrank();

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

        uint256 positionId = vesting.createLinearPlan(
            beneficiary,
            address(mockNFT),
            templateId,
            tokenIds,
            permits
        );
        vm.stopPrank();

        // Fast forward and claim some tokens
        vm.warp(block.timestamp + 100 days);
        
        vm.startPrank(beneficiary);
        uint256[] memory claimableIds = vesting.previewClaimableIds(positionId, 2);
        vesting.claim(positionId, beneficiary, claimableIds);
        vm.stopPrank();

        uint256 claimed = claimableIds.length;
        uint256 totalUnlocked = vesting.unlockedCount(positionId, block.timestamp);

        // Revoke
        vm.startPrank(issuer);
        uint256 unvested = 10 - totalUnlocked;
        uint256[] memory returnTokenIds = new uint256[](unvested);
        for (uint256 i = 0; i < unvested; i++) {
            returnTokenIds[i] = tokenIds[tokenIds.length - 1 - i];
        }

        vesting.revoke(positionId, returnTokenIds);
        vm.stopPrank();

        // Check accounting
        Vesting721Of721Plus.VestingPlan memory plan = vesting.getPlan(positionId);
        assertEq(plan.claimedCount, claimed);
        assertEq(plan.vestedCapOnRevoke, totalUnlocked);
        assertTrue(plan.revoked);
        assertEq(plan.revokeTime, block.timestamp);

        // Check that claimed tokens are with beneficiary
        for (uint256 i = 0; i < claimed; i++) {
            assertEq(mockNFT.ownerOf(claimableIds[i]), beneficiary);
        }

        // Check that returned tokens are with issuer
        for (uint256 i = 0; i < returnTokenIds.length; i++) {
            assertEq(mockNFT.ownerOf(returnTokenIds[i]), issuer);
        }
    }
}
