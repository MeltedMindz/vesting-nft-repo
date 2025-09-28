// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

// ============ EIP-4494 Interface ============

interface IERC4494 {
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        bytes calldata signature
    ) external;
}

/**
 * @title Vesting721Of721Plus
 * @dev Position NFT contract that vests ERC-721 tokens from a source collection over time.
 * Each position NFT represents a vesting plan that escrows tokenIds and unlocks them according to schedules.
 */
contract Vesting721Of721Plus is ERC721, IERC721Receiver, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // ============ Structs ============

    struct LinearTemplate {
        uint256 cliff; // Cliff period in seconds
        uint256 duration; // Total vesting duration in seconds
        uint256 slice; // Slice period in seconds (0 = no slicing)
    }

    struct Tranche {
        uint256 timestamp; // When this tranche unlocks
        uint256 count; // Cumulative count of tokens unlocked
    }

    struct VestingPlan {
        address sourceCollection; // Source ERC-721 contract
        address beneficiary; // Who can claim
        address issuer; // Who can revoke
        uint256 startTime; // When vesting starts
        uint256 totalCount; // Total tokens in plan
        uint256 claimedCount; // How many have been claimed
        bool isLinear; // true = linear, false = tranche
        bool revoked; // Whether plan has been revoked
        uint256 revokeTime; // When it was revoked
        uint256 vestedCapOnRevoke; // How many were vested when revoked
        uint256 templateId; // Template ID for linear plans (0 for tranche plans)
    }

    struct PermitInput {
        uint256 tokenId;
        uint256 deadline;
        bytes signature;
        bool usePermit;
    }

    // ============ State Variables ============

    string public baseTokenURI;
    bool public useOnchainMetadata;

    // Linear templates
    mapping(uint256 => LinearTemplate) public linearTemplates;
    uint256 public nextTemplateId = 1;

    // Vesting plans
    mapping(uint256 => VestingPlan) public plans;
    mapping(uint256 => uint256[]) public positionTokenIds; // positionId => tokenIds
    mapping(uint256 => mapping(uint256 => bool)) public released; // positionId => tokenId => released
    mapping(uint256 => string) public customTokenURI; // positionId => custom URI
    mapping(uint256 => Tranche[]) public tranches; // positionId => tranche schedule

    uint256 public nextPositionId = 1;

    // ============ Events ============

    event LinearTemplateSet(uint256 indexed templateId, uint256 cliff, uint256 duration, uint256 slice);
    event LinearTemplateRemoved(uint256 indexed templateId);
    event LinearPlanCreated(
        uint256 indexed positionId,
        address indexed beneficiary,
        address indexed sourceCollection,
        uint256 templateId,
        uint256[] tokenIds
    );
    event TranchePlanCreated(
        uint256 indexed positionId,
        address indexed beneficiary,
        address indexed sourceCollection,
        uint256[] tokenIds,
        Tranche[] tranches
    );
    event Claimed(uint256 indexed positionId, address indexed to, uint256[] tokenIds);
    event Revoked(uint256 indexed positionId, address indexed issuer, uint256[] returnedTokenIds);
    event RevokedAuto(uint256 indexed positionId, address indexed issuer, uint256[] returnedTokenIds);
    event MetadataToggled(bool useOnchainMetadata);
    event BaseTokenURISet(string newBaseURI);
    event CustomTokenURISet(uint256 indexed positionId, string uri);
    event PositionCreated(uint256 indexed positionId, address indexed beneficiary, address indexed issuer, bool isLinear);
    event TemplateRemoved(uint256 indexed templateId);

    // ============ Constructor ============

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        baseTokenURI = baseURI_;
        useOnchainMetadata = true;
    }


    // ============ Template Management ============

    /**
     * @dev Set a linear template
     */
    function setLinearTemplate(
        uint256 cliff,
        uint256 duration,
        uint256 slice
    ) external onlyOwner returns (uint256 templateId) {
        require(duration > 0, "Duration must be > 0");
        require(duration <= 10 * 365 days, "Duration too long (max 10 years)");
        require(cliff < duration, "Cliff must be < duration");
        require(slice == 0 || slice <= duration, "Slice must be <= duration");
        require(slice == 0 || slice >= 1 days, "Slice must be at least 1 day");

        templateId = nextTemplateId++;
        linearTemplates[templateId] = LinearTemplate(cliff, duration, slice);

        emit LinearTemplateSet(templateId, cliff, duration, slice);
    }

    /**
     * @dev Remove a linear template
     */
    function removeLinearTemplate(uint256 templateId) external onlyOwner {
        require(linearTemplates[templateId].duration > 0, "Template does not exist");
        delete linearTemplates[templateId];
        emit LinearTemplateRemoved(templateId);
        emit TemplateRemoved(templateId);
    }

    // ============ Plan Creation ============

    /**
     * @dev Create a linear vesting plan
     */
    function createLinearPlan(
        address beneficiary,
        address sourceCollection,
        uint256 templateId,
        uint256[] calldata tokenIds,
        PermitInput[] calldata permits
    ) external nonReentrant returns (uint256 positionId) {
        require(beneficiary != address(0), "Invalid beneficiary");
        require(sourceCollection != address(0), "Invalid source collection");
        require(tokenIds.length > 0, "No tokens provided");
        require(tokenIds.length <= 100, "Too many tokens (max 100)");
        require(permits.length == tokenIds.length, "Permits length mismatch");
        
        // Validate token IDs are unique
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 0, "Invalid token ID");
            for (uint256 j = i + 1; j < tokenIds.length; j++) {
                require(tokenIds[i] != tokenIds[j], "Duplicate token ID");
            }
        }

        LinearTemplate memory template = linearTemplates[templateId];
        require(template.duration > 0, "Invalid template");

        positionId = nextPositionId++;
        plans[positionId] = VestingPlan({
            sourceCollection: sourceCollection,
            beneficiary: beneficiary,
            issuer: msg.sender,
            startTime: block.timestamp,
            totalCount: tokenIds.length,
            claimedCount: 0,
            isLinear: true,
            revoked: false,
            revokeTime: 0,
            vestedCapOnRevoke: 0,
            templateId: templateId
        });

        positionTokenIds[positionId] = tokenIds;

        // Pull tokens with optional permits
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (permits[i].usePermit) {
                IERC4494(sourceCollection).permit(
                    address(this),
                    tokenIds[i],
                    permits[i].deadline,
                    permits[i].signature
                );
            }
            IERC721(sourceCollection).transferFrom(msg.sender, address(this), tokenIds[i]);
        }

        emit LinearPlanCreated(positionId, beneficiary, sourceCollection, templateId, tokenIds);
        emit PositionCreated(positionId, beneficiary, msg.sender, true);
        _mint(beneficiary, positionId);
    }

    /**
     * @dev Create a tranche vesting plan
     */
    function createTranchePlan(
        address beneficiary,
        address sourceCollection,
        uint256[] calldata tokenIds,
        Tranche[] calldata trancheSchedule,
        PermitInput[] calldata permits
    ) external nonReentrant returns (uint256 positionId) {
        require(beneficiary != address(0), "Invalid beneficiary");
        require(sourceCollection != address(0), "Invalid source collection");
        require(tokenIds.length > 0, "No tokens provided");
        require(tokenIds.length <= 100, "Too many tokens (max 100)");
        require(trancheSchedule.length > 0, "No tranches provided");
        require(permits.length == tokenIds.length, "Permits length mismatch");
        
        // Validate token IDs are unique
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 0, "Invalid token ID");
            for (uint256 j = i + 1; j < tokenIds.length; j++) {
                require(tokenIds[i] != tokenIds[j], "Duplicate token ID");
            }
        }

        // Validate tranches
        _validateTranches(trancheSchedule, tokenIds.length);

        positionId = nextPositionId++;
        plans[positionId] = VestingPlan({
            sourceCollection: sourceCollection,
            beneficiary: beneficiary,
            issuer: msg.sender,
            startTime: block.timestamp,
            totalCount: tokenIds.length,
            claimedCount: 0,
            isLinear: false,
            revoked: false,
            revokeTime: 0,
            vestedCapOnRevoke: 0,
            templateId: 0
        });

        positionTokenIds[positionId] = tokenIds;
        tranches[positionId] = trancheSchedule;

        // Pull tokens with optional permits
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (permits[i].usePermit) {
                IERC4494(sourceCollection).permit(
                    address(this),
                    tokenIds[i],
                    permits[i].deadline,
                    permits[i].signature
                );
            }
            IERC721(sourceCollection).transferFrom(msg.sender, address(this), tokenIds[i]);
        }

        emit TranchePlanCreated(positionId, beneficiary, sourceCollection, tokenIds, trancheSchedule);
        emit PositionCreated(positionId, beneficiary, msg.sender, false);
        _mint(beneficiary, positionId);
    }

    // ============ Claiming ============

    /**
     * @dev Claim unlocked tokens
     */
    function claim(
        uint256 positionId,
        address to,
        uint256[] calldata tokenIds
    ) external nonReentrant {
        VestingPlan storage plan = plans[positionId];
        require(ownerOf(positionId) == msg.sender, "Not position owner");
        require(to != address(0), "Invalid recipient");
        require(!plan.revoked, "Plan has been revoked");

        uint256 claimable = claimableCount(positionId);
        require(tokenIds.length <= claimable, "Too many tokens");
        require(tokenIds.length > 0, "No tokens to claim");

        // Validate and transfer tokens
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_isTokenInPlan(positionId, tokenIds[i]), "Token not in plan");
            require(!released[positionId][tokenIds[i]], "Token already released");
            require(_isTokenUnlocked(positionId, tokenIds[i]), "Token not unlocked");

            released[positionId][tokenIds[i]] = true;
            IERC721(plan.sourceCollection).transferFrom(address(this), to, tokenIds[i]);
        }

        plan.claimedCount += tokenIds.length;
        emit Claimed(positionId, to, tokenIds);
    }

    // ============ Revocation ============

    /**
     * @dev Manually revoke plan and return specified tokens
     */
    function revoke(uint256 positionId, uint256[] calldata returnTokenIds) external {
        VestingPlan storage plan = plans[positionId];
        require(plan.issuer == msg.sender, "Not issuer");
        require(!plan.revoked, "Already revoked");

        uint256 unvested = _getUnvestedCount(positionId);
        require(returnTokenIds.length == unvested, "Wrong return count");

        // Set revocation state
        plan.revoked = true;
        plan.revokeTime = block.timestamp;
        plan.vestedCapOnRevoke = _getUnlockedCount(positionId);

        // Validate and return tokens
        for (uint256 i = 0; i < returnTokenIds.length; i++) {
            require(_isTokenInPlan(positionId, returnTokenIds[i]), "Token not in plan");
            require(!released[positionId][returnTokenIds[i]], "Token already released");

            released[positionId][returnTokenIds[i]] = true;
            IERC721(plan.sourceCollection).transferFrom(address(this), plan.issuer, returnTokenIds[i]);
        }

        emit Revoked(positionId, plan.issuer, returnTokenIds);
    }

    /**
     * @dev Auto-revoke: issuer gets largest unreleased tokens
     */
    function revokeAuto(uint256 positionId) external {
        VestingPlan storage plan = plans[positionId];
        require(plan.issuer == msg.sender, "Not issuer");
        require(!plan.revoked, "Already revoked");

        uint256 unvested = _getUnvestedCount(positionId);
        require(unvested > 0, "Nothing to revoke");

        // Set revocation state
        plan.revoked = true;
        plan.revokeTime = block.timestamp;
        plan.vestedCapOnRevoke = _getUnlockedCount(positionId);

        // Find largest unreleased tokens to return
        uint256[] memory tokenIds = positionTokenIds[positionId];
        uint256[] memory returnTokenIds = new uint256[](unvested);
        uint256 returnIndex = 0;

        // Scan from end to get largest unreleased tokens
        for (uint256 i = tokenIds.length; i > 0 && returnIndex < unvested; i--) {
            uint256 tokenId = tokenIds[i - 1];
            if (!released[positionId][tokenId]) {
                returnTokenIds[returnIndex] = tokenId;
                returnIndex++;
            }
        }

        require(returnIndex == unvested, "Insufficient unreleased tokens");

        // Return tokens
        for (uint256 i = 0; i < returnTokenIds.length; i++) {
            released[positionId][returnTokenIds[i]] = true;
            IERC721(plan.sourceCollection).transferFrom(address(this), plan.issuer, returnTokenIds[i]);
        }

        emit RevokedAuto(positionId, plan.issuer, returnTokenIds);
    }

    // ============ View Functions ============

    /**
     * @dev Get unlocked count at given timestamp
     */
    function unlockedCount(uint256 positionId, uint256 timestamp) external view returns (uint256) {
        return _getUnlockedCountAtTime(positionId, timestamp);
    }

    /**
     * @dev Get claimable count now
     */
    function claimableCount(uint256 positionId) public view returns (uint256) {
        VestingPlan memory plan = plans[positionId];
        if (plan.revoked) {
            return plan.vestedCapOnRevoke > plan.claimedCount ? plan.vestedCapOnRevoke - plan.claimedCount : 0;
        }
        uint256 unlocked = _getUnlockedCount(positionId);
        return unlocked > plan.claimedCount ? unlocked - plan.claimedCount : 0;
    }

    /**
     * @dev Preview claimable token IDs
     */
    function previewClaimableIds(
        uint256 positionId,
        uint256 limit
    ) external view returns (uint256[] memory) {
        uint256 claimable = claimableCount(positionId);
        if (limit > claimable) limit = claimable;
        if (limit == 0) return new uint256[](0);

        uint256[] memory tokenIds = positionTokenIds[positionId];
        uint256[] memory result = new uint256[](limit);
        uint256 resultIndex = 0;

        // Cache plan data to avoid multiple storage reads
        VestingPlan memory plan = plans[positionId];
        uint256 unlockedAmount = _getUnlockedCount(positionId);

        for (uint256 i = 0; i < tokenIds.length && resultIndex < limit; i++) {
            uint256 tokenId = tokenIds[i];
            if (!released[positionId][tokenId]) {
                // Check if token is unlocked using cached data
                bool isUnlocked = plan.revoked ? 
                    i < plan.vestedCapOnRevoke : 
                    i < unlockedAmount;
                
                if (isUnlocked) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }
        }

        return result;
    }

    /**
     * @dev Get plan details
     */
    function getPlan(uint256 positionId) external view returns (VestingPlan memory) {
        return plans[positionId];
    }

    /**
     * @dev Get next unlock time
     */
    function nextUnlockTime(uint256 positionId) external view returns (uint256) {
        return _getNextUnlockTime(positionId);
    }

    // ============ Metadata ============

    /**
     * @dev Toggle on-chain metadata
     */
    function toggleOnchainMetadata() external onlyOwner {
        useOnchainMetadata = !useOnchainMetadata;
        emit MetadataToggled(useOnchainMetadata);
    }

    /**
     * @dev Set base token URI
     */
    function setBaseTokenURI(string calldata newBaseURI) external onlyOwner {
        require(bytes(newBaseURI).length > 0, "Base URI cannot be empty");
        baseTokenURI = newBaseURI;
        emit BaseTokenURISet(newBaseURI);
    }

    /**
     * @dev Set custom token URI for a position
     */
    function setCustomTokenURI(uint256 positionId, string calldata uri) external {
        require(ownerOf(positionId) == msg.sender, "Not position owner");
        require(bytes(uri).length > 0, "URI cannot be empty");
        require(bytes(uri).length <= 2048, "URI too long (max 2048 chars)");
        customTokenURI[positionId] = uri;
        emit CustomTokenURISet(positionId, uri);
    }

    /**
     * @dev Get token URI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");

        if (bytes(customTokenURI[tokenId]).length > 0) {
            return customTokenURI[tokenId];
        }

        if (useOnchainMetadata) {
            return _generateOnchainMetadata(tokenId);
        }

        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    // ============ Internal Functions ============

    function _validateTranches(Tranche[] calldata trancheSchedule, uint256 totalCount) internal view {
        require(trancheSchedule.length > 0, "No tranches provided");
        require(trancheSchedule.length <= 50, "Too many tranches (max 50)");
        require(trancheSchedule[0].timestamp > block.timestamp, "First tranche must be in the future");
        require(trancheSchedule[trancheSchedule.length - 1].count == totalCount, "Last tranche must equal total");

        for (uint256 i = 0; i < trancheSchedule.length; i++) {
            require(trancheSchedule[i].timestamp > 0, "Invalid timestamp");
            require(trancheSchedule[i].count > 0, "Invalid count");
            require(trancheSchedule[i].timestamp <= block.timestamp + 10 * 365 days, "Tranche too far in future");
        }

        for (uint256 i = 1; i < trancheSchedule.length; i++) {
            require(
                trancheSchedule[i].timestamp > trancheSchedule[i - 1].timestamp,
                "Tranches must be increasing"
            );
            require(
                trancheSchedule[i].count >= trancheSchedule[i - 1].count,
                "Counts must be non-decreasing"
            );
        }
    }

    function _isTokenInPlan(uint256 positionId, uint256 tokenId) internal view returns (bool) {
        uint256[] memory tokenIds = positionTokenIds[positionId];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) return true;
        }
        return false;
    }

    function _isTokenUnlocked(uint256 positionId, uint256 tokenId) internal view returns (bool) {
        VestingPlan memory plan = plans[positionId];
        if (plan.revoked) {
            // After revocation, only tokens that were vested at revocation time can be claimed
            return _getTokenIndex(positionId, tokenId) < plan.vestedCapOnRevoke;
        }
        return _getTokenIndex(positionId, tokenId) < _getUnlockedCount(positionId);
    }

    function _getTokenIndex(uint256 positionId, uint256 tokenId) internal view returns (uint256) {
        uint256[] memory tokenIds = positionTokenIds[positionId];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) return i;
        }
        revert("Token not found");
    }

    function _getUnlockedCount(uint256 positionId) internal view returns (uint256) {
        return _getUnlockedCountAtTime(positionId, block.timestamp);
    }

    function _getUnlockedCountAtTime(uint256 positionId, uint256 timestamp) internal view returns (uint256) {
        VestingPlan memory plan = plans[positionId];
        if (timestamp < plan.startTime) return 0;

        if (plan.isLinear) {
            return _getLinearUnlockedCount(positionId, timestamp);
        } else {
            return _getTrancheUnlockedCount(positionId, timestamp);
        }
    }

    function _getLinearUnlockedCount(uint256 positionId, uint256 timestamp) internal view returns (uint256) {
        VestingPlan memory plan = plans[positionId];
        LinearTemplate memory template = linearTemplates[plan.templateId];

        uint256 elapsed = timestamp - plan.startTime;
        if (elapsed < template.cliff) return 0;
        if (elapsed >= template.duration) return plan.totalCount;

        uint256 vested = (plan.totalCount * elapsed) / template.duration;
        if (template.slice > 0) {
            vested = (vested / template.slice) * template.slice;
        }

        return vested;
    }

    function _getTrancheUnlockedCount(uint256 positionId, uint256 timestamp) internal view returns (uint256) {
        Tranche[] memory trancheSchedule = tranches[positionId];
        uint256 unlocked = 0;

        for (uint256 i = 0; i < trancheSchedule.length; i++) {
            if (timestamp >= trancheSchedule[i].timestamp) {
                unlocked = trancheSchedule[i].count;
            } else {
                break;
            }
        }

        return unlocked;
    }

    function _getUnvestedCount(uint256 positionId) internal view returns (uint256) {
        VestingPlan memory plan = plans[positionId];
        uint256 unlocked = _getUnlockedCount(positionId);
        return plan.totalCount - unlocked;
    }

    function _getNextUnlockTime(uint256 positionId) internal view returns (uint256) {
        VestingPlan memory plan = plans[positionId];
        if (plan.isLinear) {
            return plan.startTime; // Linear starts immediately
        } else {
            Tranche[] memory trancheSchedule = tranches[positionId];
            for (uint256 i = 0; i < trancheSchedule.length; i++) {
                if (block.timestamp < trancheSchedule[i].timestamp) {
                    return trancheSchedule[i].timestamp;
                }
            }
            return 0; // All unlocked
        }
    }

    function _generateOnchainMetadata(uint256 tokenId) internal view returns (string memory) {
        VestingPlan memory plan = plans[tokenId];
        (uint256 unlockedNow, uint256 nextUnlock) = _unlockedNowAndNext(tokenId);

        string memory json = string(
            abi.encodePacked(
                '{"name":"Vesting Position #',
                tokenId.toString(),
                '","description":"NFT vesting position that escrows tokens from a source collection and unlocks them over time.",',
                '"attributes":[',
                '{"trait_type":"Schedule Kind","value":"',
                plan.isLinear ? "Linear" : "Tranche",
                '"},',
                '{"trait_type":"Asset","value":"',
                _toHexString(plan.sourceCollection),
                '"},',
                '{"trait_type":"Total NFTs","value":',
                plan.totalCount.toString(),
                '},',
                '{"trait_type":"Claimed","value":',
                plan.claimedCount.toString(),
                '},',
                '{"trait_type":"Unlocked Now","value":',
                unlockedNow.toString(),
                '},',
                '{"trait_type":"Remaining Claimable","value":',
                (unlockedNow - plan.claimedCount).toString(),
                '},',
                '{"trait_type":"Revocable","value":',
                plan.revoked ? "No" : "Yes",
                '},',
                '{"trait_type":"Revoked","value":',
                plan.revoked ? "Yes" : "No",
                '}],',
                '"properties":{"nextUnlockTime":',
                nextUnlock.toString(),
                '}}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", _base64Encode(bytes(json))));
    }

    function _unlockedNowAndNext(uint256 positionId) internal view returns (uint256 unlockedNow, uint256 nextUnlock) {
        unlockedNow = _getUnlockedCount(positionId);
        nextUnlock = _getNextUnlockTime(positionId);
    }

    function _toHexString(address addr) internal pure returns (string memory) {
        return string(abi.encodePacked("0x", _toHexString(uint160(addr), 20)));
    }

    function _toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = 2 * length; i > 0; i--) {
            buffer[i - 1] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }

    function _base64Encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, mload(data)) {
                i := add(i, 3)
            } {
                let input := and(mload(add(data, add(32, i))), 0xffffff)

                let out := mload(add(tablePtr, and(shr(250, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(244, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(238, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(232, input), 0x3F))), 0xFF))
                out := shl(8, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    // ============ ERC721Receiver ============

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
