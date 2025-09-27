// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title MockERC721Permit4494
 * @dev ERC-721 with EIP-4494 permit functionality for testing signature-based transfers
 */
contract MockERC721Permit4494 is ERC721, Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    uint256 public nextTokenId = 1;
    mapping(uint256 => uint256) public nonces;

    // EIP-712 type hashes
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    /**
     * @dev Mint a token to the given address
     */
    function mint(address to) external onlyOwner returns (uint256) {
        uint256 tokenId = nextTokenId++;
        _mint(to, tokenId);
        return tokenId;
    }

    /**
     * @dev Mint multiple tokens to the given address
     */
    function mintBatch(address to, uint256 count) external onlyOwner returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            tokenIds[i] = nextTokenId++;
            _mint(to, tokenIds[i]);
        }
        return tokenIds;
    }

    /**
     * @dev Mint a specific token ID (for testing)
     */
    function mintWithId(address to, uint256 tokenId) external onlyOwner {
        require(tokenId > 0, "Invalid token ID");
        if (tokenId >= nextTokenId) {
            nextTokenId = tokenId + 1;
        }
        _mint(to, tokenId);
    }

    /**
     * @dev Get the total supply
     */
    function totalSupply() external view returns (uint256) {
        return nextTokenId - 1;
    }

    /**
     * @dev EIP-4494 permit function
     * @param spender Address that will be approved
     * @param tokenId Token ID to approve
     * @param deadline Expiration time for the permit
     * @param signature Signature from the token owner
     */
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        bytes calldata signature
    ) external {
        require(block.timestamp <= deadline, "Permit expired");
        require(_exists(tokenId), "Token does not exist");

        address owner = ownerOf(tokenId);
        require(owner != address(0), "Invalid owner");

        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TYPEHASH, spender, tokenId, nonces[tokenId], deadline)
        );

        bytes32 domainHash = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainHash, structHash));
        address signer = digest.recover(signature);

        require(signer == owner, "Invalid signature");
        require(signer != address(0), "Invalid signer");

        nonces[tokenId]++;

        _approve(spender, tokenId);
    }

    /**
     * @dev Get the nonce for a token
     */
    function getNonce(uint256 tokenId) external view returns (uint256) {
        return nonces[tokenId];
    }

    /**
     * @dev Get the domain separator
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }
}
