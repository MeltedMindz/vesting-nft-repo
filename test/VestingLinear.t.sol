// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Vesting721Of721Plus.sol";
import "../src/mocks/MockERC721.sol";
import "../src/mocks/MockERC721Permit4494.sol";

/**
 * @title VestingLinearTest
 * @dev Test linear vesting functionality
 */
contract VestingLinearTest is Test {
    Vesting721Of721Plus public vesting;
    MockERC721 public mockNFT;
    MockERC721Permit4494 public mockNFTWithPermit;

    address public owner = address(0x1);
    address public beneficiary = address(0x2);
    address public issuer = address(0x3);

    uint256 public templateId;
    uint256 public positionId;

    function setUp() public {
        vm.startPrank(owner);
        vesting = new Vesting721Of721Plus("Vesting Positions", "VEST", "https://api.example.com/metadata/");
        mockNFT = new MockERC721("Test NFT", "TNFT");
        mockNFTWithPermit = new MockERC721Permit4494("Test NFT Permit", "TNFT-P");
        vm.stopPrank();

        // Set up linear template
        vm.startPrank(owner);
        templateId = vesting.setLinearTemplate(30 days, 365 days, 1 days); // 1 month cliff, 1 year duration, 1 day slice
        vm.stopPrank();
    }

    function testCreateLinearPlan() public {
        // Mint some NFTs to issuer
        vm.startPrank(issuer);
        uint256[] memory tokenIds = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            tokenIds[i] = mockNFT.mint(issuer);
        }

        // Create permit inputs (no permits needed for basic test)
        Vesting721Of721Plus.PermitInput[] memory permits = new Vesting721Of721Plus.PermitInput[](3);
        for (uint256 i = 0; i < 3; i++) {
            permits[i] = Vesting721Of721Plus.PermitInput({
                tokenId: tokenIds[i],
                deadline: 0,
                signature: "",
                usePermit: false
            });
        }

        // Create linear plan
        uint256 positionId = vesting.createLinearPlan(
            beneficiary,
            address(mockNFT),
            templateId,
            tokenIds,
            permits
        );
        vm.stopPrank();

        // Check position was created
        assertEq(vesting.ownerOf(positionId), beneficiary);
        
        Vesting721Of721Plus.VestingPlan memory plan = vesting.getPlan(positionId);
        assertEq(plan.beneficiary, beneficiary);
        assertEq(plan.sourceCollection, address(mockNFT));
        assertEq(plan.totalCount, 3);
        assertEq(plan.claimedCount, 0);
        assertTrue(plan.isLinear);
        assertFalse(plan.revoked);
    }

    function testLinearVestingWithCliff() public {
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

        uint256 positionId = vesting.createLinearPlan(
            beneficiary,
            address(mockNFT),
            templateId,
            tokenIds,
            permits
        );
        vm.stopPrank();

        // Before cliff - nothing unlocked
        assertEq(vesting.unlockedCount(positionId, block.timestamp), 0);
        assertEq(vesting.claimableCount(positionId), 0);

        // At cliff - still nothing (cliff is 30 days, duration is 365 days)
        vm.warp(block.timestamp + 30 days);
        assertEq(vesting.unlockedCount(positionId, block.timestamp), 0);
        assertEq(vesting.claimableCount(positionId), 0);

        // After cliff - some tokens unlocked
        vm.warp(block.timestamp + 30 days); // 60 days total
        uint256 actualUnlocked = vesting.unlockedCount(positionId, block.timestamp);
        assertTrue(actualUnlocked > 0);
        assertTrue(actualUnlocked <= 10);
        assertEq(vesting.claimableCount(positionId), actualUnlocked);

        // At end of duration - all tokens unlocked
        vm.warp(block.timestamp + 305 days); // 365 days total
        assertEq(vesting.unlockedCount(positionId, block.timestamp), 10);
        assertEq(vesting.claimableCount(positionId), 10);
    }

    function testLinearVestingWithSlice() public {
        // Create plan with slice
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

        // Test slice behavior
        vm.warp(block.timestamp + 30 days + 1 days); // Just after cliff
        uint256 unlocked = vesting.unlockedCount(positionId, block.timestamp);
        assertTrue(unlocked > 0);
        assertTrue(unlocked <= 5);

        // Test that slice rounds down
        vm.warp(block.timestamp + 1 days); // 1 day later
        uint256 newUnlocked = vesting.unlockedCount(positionId, block.timestamp);
        assertTrue(newUnlocked >= unlocked);
    }

    function testClaiming() public {
        // Create plan
        vm.startPrank(issuer);
        uint256[] memory tokenIds = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            tokenIds[i] = mockNFT.mint(issuer);
        }

        Vesting721Of721Plus.PermitInput[] memory permits = new Vesting721Of721Plus.PermitInput[](3);
        for (uint256 i = 0; i < 3; i++) {
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
        vm.warp(block.timestamp + 60 days);

        // Claim tokens
        vm.startPrank(beneficiary);
        uint256[] memory claimableIds = vesting.previewClaimableIds(positionId, 2);
        assertTrue(claimableIds.length > 0);

        vesting.claim(positionId, beneficiary, claimableIds);
        vm.stopPrank();

        // Check tokens were transferred
        for (uint256 i = 0; i < claimableIds.length; i++) {
            assertEq(mockNFT.ownerOf(claimableIds[i]), beneficiary);
        }

        // Check claimed count updated
        Vesting721Of721Plus.VestingPlan memory plan = vesting.getPlan(positionId);
        assertEq(plan.claimedCount, claimableIds.length);
    }

    function testPositionTransfer() public {
        // Create plan
        vm.startPrank(issuer);
        uint256[] memory tokenIds = new uint256[](2);
        for (uint256 i = 0; i < 2; i++) {
            tokenIds[i] = mockNFT.mint(issuer);
        }

        Vesting721Of721Plus.PermitInput[] memory permits = new Vesting721Of721Plus.PermitInput[](2);
        for (uint256 i = 0; i < 2; i++) {
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

        // Transfer position to new owner
        address newOwner = address(0x4);
        vm.startPrank(beneficiary);
        vesting.transferFrom(beneficiary, newOwner, positionId);
        vm.stopPrank();

        // New owner should be able to claim
        assertEq(vesting.ownerOf(positionId), newOwner);

        // Fast forward and claim
        vm.warp(block.timestamp + 60 days);
        vm.startPrank(newOwner);
        uint256[] memory claimableIds = vesting.previewClaimableIds(positionId, 1);
        if (claimableIds.length > 0) {
            vesting.claim(positionId, newOwner, claimableIds);
        }
        vm.stopPrank();
    }

    function testInvalidOperations() public {
        // Create plan
        vm.startPrank(issuer);
        uint256[] memory tokenIds = new uint256[](2);
        for (uint256 i = 0; i < 2; i++) {
            tokenIds[i] = mockNFT.mint(issuer);
        }

        Vesting721Of721Plus.PermitInput[] memory permits = new Vesting721Of721Plus.PermitInput[](2);
        for (uint256 i = 0; i < 2; i++) {
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

        // Non-owner cannot claim
        vm.startPrank(address(0x5));
        vm.expectRevert("Not position owner");
        vesting.claim(positionId, address(0x5), new uint256[](1));
        vm.stopPrank();

        // Cannot claim before unlock
        vm.startPrank(beneficiary);
        vm.expectRevert("Too many tokens");
        vesting.claim(positionId, beneficiary, new uint256[](1));
        vm.stopPrank();
    }
}
