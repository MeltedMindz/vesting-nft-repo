// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockERC721
 * @dev Simple mintable ERC-721 for testing vesting functionality
 */
contract MockERC721 is ERC721, Ownable {
    uint256 public nextTokenId = 1;

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
}
