// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Vesting721Of721Plus.sol";
import "../src/mocks/MockERC721Permit4494.sol";

/**
 * @title Permit4494Test
 * @dev Test EIP-4494 permit functionality
 */
contract Permit4494Test is Test {
    Vesting721Of721Plus public vesting;
    MockERC721Permit4494 public mockNFT;

    address public owner = address(0x1);
    address public beneficiary = address(0x2);
    address public issuer = address(0x3);
    uint256 private issuerKey = 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;

    function setUp() public {
        vm.startPrank(owner);
        vesting = new Vesting721Of721Plus("Vesting Positions", "VEST", "https://api.example.com/metadata/");
        mockNFT = new MockERC721Permit4494("Test NFT Permit", "TNFT-P");
        vm.stopPrank();

        // Set up issuer with private key
        vm.startPrank(vm.addr(issuerKey));
        vm.stopPrank();
    }

    function testCreatePlanWithPermit() public {
        // Create linear template
        vm.startPrank(owner);
        uint256 templateId = vesting.setLinearTemplate(0, 365 days, 1 days);
        vm.stopPrank();

        // Mint NFTs to issuer
        vm.startPrank(vm.addr(issuerKey));
        uint256[] memory tokenIds = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            tokenIds[i] = mockNFT.mint(vm.addr(issuerKey));
        }
        vm.stopPrank();

        // Create permits for each token
        Vesting721Of721Plus.PermitInput[] memory permits = new Vesting721Of721Plus.PermitInput[](3);
        for (uint256 i = 0; i < 3; i++) {
            permits[i] = Vesting721Of721Plus.PermitInput({
                tokenId: tokenIds[i],
                deadline: block.timestamp + 1 hours,
                signature: _createPermitSignature(tokenIds[i], block.timestamp + 1 hours),
                usePermit: true
            });
        }

        // Create plan with permits
        vm.startPrank(vm.addr(issuerKey));
        uint256 positionId = vesting.createLinearPlan(
            beneficiary,
            address(mockNFT),
            templateId,
            tokenIds,
            permits
        );
        vm.stopPrank();

        // Check plan was created
        assertEq(vesting.ownerOf(positionId), beneficiary);
        
        Vesting721Of721Plus.VestingPlan memory plan = vesting.getPlan(positionId);
        assertEq(plan.beneficiary, beneficiary);
        assertEq(plan.sourceCollection, address(mockNFT));
        assertEq(plan.totalCount, 3);

        // Check tokens are in vesting contract
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(mockNFT.ownerOf(tokenIds[i]), address(vesting));
        }
    }

    function testCreatePlanWithoutPermit() public {
        // Create linear template
        vm.startPrank(owner);
        uint256 templateId = vesting.setLinearTemplate(0, 365 days, 1 days);
        vm.stopPrank();

        // Mint NFTs to issuer
        vm.startPrank(vm.addr(issuerKey));
        uint256[] memory tokenIds = new uint256[](2);
        for (uint256 i = 0; i < 2; i++) {
            tokenIds[i] = mockNFT.mint(vm.addr(issuerKey));
        }

        // Approve vesting contract
        for (uint256 i = 0; i < 2; i++) {
            mockNFT.approve(address(vesting), tokenIds[i]);
        }

        // Create permits (no permits needed)
        Vesting721Of721Plus.PermitInput[] memory permits = new Vesting721Of721Plus.PermitInput[](2);
        for (uint256 i = 0; i < 2; i++) {
            permits[i] = Vesting721Of721Plus.PermitInput({
                tokenId: tokenIds[i],
                deadline: 0,
                signature: "",
                usePermit: false
            });
        }

        // Create plan without permits
        uint256 positionId = vesting.createLinearPlan(
            beneficiary,
            address(mockNFT),
            templateId,
            tokenIds,
            permits
        );
        vm.stopPrank();

        // Check plan was created
        assertEq(vesting.ownerOf(positionId), beneficiary);
        
        Vesting721Of721Plus.VestingPlan memory plan = vesting.getPlan(positionId);
        assertEq(plan.beneficiary, beneficiary);
        assertEq(plan.sourceCollection, address(mockNFT));
        assertEq(plan.totalCount, 2);
    }

    function testInvalidPermitSignature() public {
        // Create linear template
        vm.startPrank(owner);
        uint256 templateId = vesting.setLinearTemplate(0, 365 days, 1 days);
        vm.stopPrank();

        // Mint NFT to issuer
        vm.startPrank(vm.addr(issuerKey));
        uint256 tokenId = mockNFT.mint(vm.addr(issuerKey));
        vm.stopPrank();

        // Create invalid permit
        Vesting721Of721Plus.PermitInput[] memory permits = new Vesting721Of721Plus.PermitInput[](1);
        permits[0] = Vesting721Of721Plus.PermitInput({
            tokenId: tokenId,
            deadline: block.timestamp + 1 hours,
            signature: _createInvalidPermitSignature(tokenId, block.timestamp + 1 hours),
            usePermit: true
        });

        // Should fail with invalid signature
        vm.startPrank(vm.addr(issuerKey));
        vm.expectRevert();
        vesting.createLinearPlan(
            beneficiary,
            address(mockNFT),
            templateId,
            new uint256[](1),
            permits
        );
        vm.stopPrank();
    }

    function testExpiredPermit() public {
        // Create linear template
        vm.startPrank(owner);
        uint256 templateId = vesting.setLinearTemplate(0, 365 days, 1 days);
        vm.stopPrank();

        // Mint NFT to issuer
        vm.startPrank(vm.addr(issuerKey));
        uint256 tokenId = mockNFT.mint(vm.addr(issuerKey));
        vm.stopPrank();

        // Create expired permit
        Vesting721Of721Plus.PermitInput[] memory permits = new Vesting721Of721Plus.PermitInput[](1);
        permits[0] = Vesting721Of721Plus.PermitInput({
            tokenId: tokenId,
            deadline: block.timestamp - 1 hours, // Expired
            signature: _createPermitSignature(tokenId, block.timestamp - 1 hours),
            usePermit: true
        });

        // Should fail with expired permit
        vm.startPrank(vm.addr(issuerKey));
        vm.expectRevert("Permit expired");
        vesting.createLinearPlan(
            beneficiary,
            address(mockNFT),
            templateId,
            new uint256[](1),
            permits
        );
        vm.stopPrank();
    }

    function testMixedPermitAndApproval() public {
        // Create linear template
        vm.startPrank(owner);
        uint256 templateId = vesting.setLinearTemplate(0, 365 days, 1 days);
        vm.stopPrank();

        // Mint NFTs to issuer
        vm.startPrank(vm.addr(issuerKey));
        uint256[] memory tokenIds = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            tokenIds[i] = mockNFT.mint(vm.addr(issuerKey));
        }

        // Approve first token, use permit for second, approve third
        mockNFT.approve(address(vesting), tokenIds[0]);
        mockNFT.approve(address(vesting), tokenIds[2]);

        // Create mixed permits
        Vesting721Of721Plus.PermitInput[] memory permits = new Vesting721Of721Plus.PermitInput[](3);
        permits[0] = Vesting721Of721Plus.PermitInput({
            tokenId: tokenIds[0],
            deadline: 0,
            signature: "",
            usePermit: false
        });
        permits[1] = Vesting721Of721Plus.PermitInput({
            tokenId: tokenIds[1],
            deadline: block.timestamp + 1 hours,
            signature: _createPermitSignature(tokenIds[1], block.timestamp + 1 hours),
            usePermit: true
        });
        permits[2] = Vesting721Of721Plus.PermitInput({
            tokenId: tokenIds[2],
            deadline: 0,
            signature: "",
            usePermit: false
        });

        // Create plan with mixed permits
        uint256 positionId = vesting.createLinearPlan(
            beneficiary,
            address(mockNFT),
            templateId,
            tokenIds,
            permits
        );
        vm.stopPrank();

        // Check plan was created
        assertEq(vesting.ownerOf(positionId), beneficiary);
        
        Vesting721Of721Plus.VestingPlan memory plan = vesting.getPlan(positionId);
        assertEq(plan.beneficiary, beneficiary);
        assertEq(plan.sourceCollection, address(mockNFT));
        assertEq(plan.totalCount, 3);
    }

    function testTranchePlanWithPermit() public {
        // Create tranche schedule
        Vesting721Of721Plus.Tranche[] memory tranches = new Vesting721Of721Plus.Tranche[](2);
        tranches[0] = Vesting721Of721Plus.Tranche(block.timestamp + 30 days, 2);
        tranches[1] = Vesting721Of721Plus.Tranche(block.timestamp + 60 days, 3);

        // Mint NFTs to issuer
        vm.startPrank(vm.addr(issuerKey));
        uint256[] memory tokenIds = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            tokenIds[i] = mockNFT.mint(vm.addr(issuerKey));
        }

        // Create permits for tranche plan
        Vesting721Of721Plus.PermitInput[] memory permits = new Vesting721Of721Plus.PermitInput[](3);
        for (uint256 i = 0; i < 3; i++) {
            permits[i] = Vesting721Of721Plus.PermitInput({
                tokenId: tokenIds[i],
                deadline: block.timestamp + 1 hours,
                signature: _createPermitSignature(tokenIds[i], block.timestamp + 1 hours),
                usePermit: true
            });
        }

        // Create tranche plan with permits
        uint256 positionId = vesting.createTranchePlan(
            beneficiary,
            address(mockNFT),
            tokenIds,
            tranches,
            permits
        );
        vm.stopPrank();

        // Check plan was created
        assertEq(vesting.ownerOf(positionId), beneficiary);
        
        Vesting721Of721Plus.VestingPlan memory plan = vesting.getPlan(positionId);
        assertEq(plan.beneficiary, beneficiary);
        assertEq(plan.sourceCollection, address(mockNFT));
        assertEq(plan.totalCount, 3);
        assertFalse(plan.isLinear);
    }

    // Helper function to create permit signature
    function _createPermitSignature(uint256 tokenId, uint256 deadline) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"),
                address(vesting),
                tokenId,
                0, // nonce
                deadline
            )
        );

        bytes32 domainHash = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Test NFT Permit")),
                keccak256(bytes("1")),
                block.chainid,
                address(mockNFT)
            )
        );

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainHash, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(issuerKey, digest);
        return abi.encodePacked(r, s, v);
    }

    // Helper function to create invalid permit signature
    function _createInvalidPermitSignature(uint256 tokenId, uint256 deadline) internal pure returns (bytes memory) {
        // Return invalid signature
        return abi.encodePacked(
            bytes32(uint256(0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef)),
            bytes32(uint256(0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890)),
            uint8(27)
        );
    }
}
