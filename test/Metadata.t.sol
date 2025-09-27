// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Vesting721Of721Plus.sol";
import "../src/mocks/MockERC721.sol";

/**
 * @title MetadataTest
 * @dev Test metadata functionality
 */
contract MetadataTest is Test {
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

    function testOnchainMetadata() public {
        // Create linear plan
        vm.startPrank(owner);
        uint256 templateId = vesting.setLinearTemplate(30 days, 365 days, 1 days);
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

        // Test on-chain metadata
        string memory uri = vesting.tokenURI(positionId);
        assertTrue(bytes(uri).length > 0);
        assertTrue(_startsWith(uri, "data:application/json;base64,"));

        // Decode and verify JSON structure
        string memory json = _decodeBase64(_substring(uri, 29)); // Remove "data:application/json;base64,"
        assertTrue(_contains(json, "Vesting Position #"));
        assertTrue(_contains(json, "Linear"));
        assertTrue(_contains(json, "Total NFTs"));
        assertTrue(_contains(json, "Claimed"));
        assertTrue(_contains(json, "Unlocked Now"));
        assertTrue(_contains(json, "Remaining Claimable"));
        assertTrue(_contains(json, "Revocable"));
        assertTrue(_contains(json, "Revoked"));
        assertTrue(_contains(json, "nextUnlockTime"));
    }

    function testCustomTokenURI() public {
        // Create plan
        vm.startPrank(owner);
        uint256 templateId = vesting.setLinearTemplate(0, 365 days, 1 days);
        vm.stopPrank();

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

        // Set custom URI
        string memory customURI = "https://custom-api.com/metadata/123";
        vm.startPrank(beneficiary);
        vesting.setCustomTokenURI(positionId, customURI);
        vm.stopPrank();

        // Check custom URI is returned
        assertEq(vesting.tokenURI(positionId), customURI);

        // Owner can also set custom URI
        string memory ownerURI = "https://owner-api.com/metadata/123";
        vm.startPrank(owner);
        vesting.setCustomTokenURI(positionId, ownerURI);
        vm.stopPrank();

        assertEq(vesting.tokenURI(positionId), ownerURI);
    }

    function testToggleOnchainMetadata() public {
        // Create plan
        vm.startPrank(owner);
        uint256 templateId = vesting.setLinearTemplate(0, 365 days, 1 days);
        vm.stopPrank();

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

        // Initially on-chain metadata is enabled
        string memory uri1 = vesting.tokenURI(positionId);
        assertTrue(_startsWith(uri1, "data:application/json;base64,"));

        // Toggle off
        vm.startPrank(owner);
        vesting.toggleOnchainMetadata();
        vm.stopPrank();

        assertFalse(vesting.useOnchainMetadata());
        string memory uri2 = vesting.tokenURI(positionId);
        assertEq(uri2, "https://api.example.com/metadata/1");

        // Toggle back on
        vm.startPrank(owner);
        vesting.toggleOnchainMetadata();
        vm.stopPrank();

        assertTrue(vesting.useOnchainMetadata());
        string memory uri3 = vesting.tokenURI(positionId);
        assertTrue(_startsWith(uri3, "data:application/json;base64,"));
    }

    function testNextUnlockTime() public {
        // Create linear plan
        vm.startPrank(owner);
        uint256 templateId = vesting.setLinearTemplate(30 days, 365 days, 1 days);
        vm.stopPrank();

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

        // Test next unlock time for linear (should be start time)
        uint256 nextUnlock = vesting.nextUnlockTime(positionId);
        Vesting721Of721Plus.VestingPlan memory plan = vesting.getPlan(positionId);
        assertEq(nextUnlock, plan.startTime);

        // Create tranche plan
        Vesting721Of721Plus.Tranche[] memory tranches = new Vesting721Of721Plus.Tranche[](2);
        tranches[0] = Vesting721Of721Plus.Tranche(block.timestamp + 30 days, 1);
        tranches[1] = Vesting721Of721Plus.Tranche(block.timestamp + 60 days, 3);

        vm.startPrank(issuer);
        uint256[] memory trancheTokenIds = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            trancheTokenIds[i] = mockNFT.mint(issuer);
        }

        Vesting721Of721Plus.PermitInput[] memory tranchePermits = new Vesting721Of721Plus.PermitInput[](3);
        for (uint256 i = 0; i < 3; i++) {
            tranchePermits[i] = Vesting721Of721Plus.PermitInput({
                tokenId: trancheTokenIds[i],
                deadline: 0,
                signature: "",
                usePermit: false
            });
        }

        uint256 tranchePositionId = vesting.createTranchePlan(
            beneficiary,
            address(mockNFT),
            trancheTokenIds,
            tranches,
            tranchePermits
        );
        vm.stopPrank();

        // Test next unlock time for tranche
        uint256 trancheNextUnlock = vesting.nextUnlockTime(tranchePositionId);
        assertEq(trancheNextUnlock, block.timestamp + 30 days);

        // Fast forward past first tranche
        vm.warp(block.timestamp + 30 days);
        uint256 newNextUnlock = vesting.nextUnlockTime(tranchePositionId);
        assertEq(newNextUnlock, block.timestamp + 30 days); // 60 days from start

        // Fast forward past all tranches
        vm.warp(block.timestamp + 30 days);
        uint256 finalNextUnlock = vesting.nextUnlockTime(tranchePositionId);
        assertEq(finalNextUnlock, 0); // All unlocked
    }

    function testMetadataAfterRevoke() public {
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

        // Fast forward and revoke
        vm.warp(block.timestamp + 100 days);
        
        vm.startPrank(issuer);
        uint256 unvested = 5 - vesting.unlockedCount(positionId, block.timestamp);
        uint256[] memory returnTokenIds = new uint256[](unvested);
        for (uint256 i = 0; i < unvested; i++) {
            returnTokenIds[i] = tokenIds[tokenIds.length - 1 - i];
        }

        vesting.revoke(positionId, returnTokenIds);
        vm.stopPrank();

        // Check metadata reflects revoked state
        string memory uri = vesting.tokenURI(positionId);
        string memory json = _decodeBase64(_substring(uri, 29));
        assertTrue(_contains(json, '"Revoked","value":"Yes"'));
        assertTrue(_contains(json, '"Revocable","value":"No"'));
    }

    // Helper functions
    function _startsWith(string memory str, string memory prefix) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory prefixBytes = bytes(prefix);
        
        if (strBytes.length < prefixBytes.length) return false;
        
        for (uint256 i = 0; i < prefixBytes.length; i++) {
            if (strBytes[i] != prefixBytes[i]) return false;
        }
        return true;
    }

    function _substring(string memory str, uint256 startIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(strBytes.length - startIndex);
        
        for (uint256 i = startIndex; i < strBytes.length; i++) {
            result[i - startIndex] = strBytes[i];
        }
        
        return string(result);
    }

    function _contains(string memory str, string memory substr) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory substrBytes = bytes(substr);
        
        if (substrBytes.length > strBytes.length) return false;
        
        for (uint256 i = 0; i <= strBytes.length - substrBytes.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < substrBytes.length; j++) {
                if (strBytes[i + j] != substrBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) return true;
        }
        return false;
    }

    function _decodeBase64(string memory data) internal pure returns (string memory) {
        // Simple base64 decoder for testing
        // In production, use a proper base64 library
        return data; // Placeholder - would need proper base64 decoding
    }
}
