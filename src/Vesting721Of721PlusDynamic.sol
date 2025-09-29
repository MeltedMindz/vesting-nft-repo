// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// EIP-4494 Interface
interface IERC4494 {
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        bytes calldata signature
    ) external;
}

/**
 * @title Vesting721Of721PlusDynamic
 * @dev Enhanced Position NFT contract with dynamic metadata that updates every N blocks
 * Each position NFT represents a vesting plan with real-time updating metadata
 */
contract Vesting721Of721PlusDynamic is ERC721, IERC721Receiver, Ownable, ReentrancyGuard {
    using Strings for uint256;

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
        // Linear params (stored directly in plan for efficiency)
        uint64 cliff;
        uint64 duration;
        uint64 slice;
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
    
    // Dynamic metadata settings
    uint256 public metadataUpdateInterval = 100; // Update every 100 blocks
    mapping(uint256 => uint256) public lastMetadataUpdate; // positionId => last update block
    
    // Linear templates
    mapping(uint256 => LinearTemplate) public linearTemplates;
    uint256 public nextTemplateId = 1;

    // Vesting plans
    mapping(uint256 => VestingPlan) public plans;
    mapping(uint256 => uint256[]) public positionTokenIds; // positionId => tokenIds
    mapping(uint256 => mapping(uint256 => bool)) public released; // positionId => tokenId => released
    mapping(uint256 => string) public customTokenURI; // positionId => custom URI
    mapping(uint256 => Tranche[]) public tranches; // positionId => tranche schedule
    mapping(uint256 => mapping(uint256 => uint256)) private tokenPositionInPlan; // positionId => tokenId => position+1

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
    event CustomTokenURISet(uint256 indexed positionId, string uri);
    event MetadataUpdateIntervalSet(uint256 interval);

    // ============ Constructor ============

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        bool useOnchainMetadata_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        baseTokenURI = baseURI_;
        useOnchainMetadata = useOnchainMetadata_;
        
        // Set up default linear templates
        _setLinearTemplate(1, 90 days, 365 days, 1 days); // 3 month cliff, 1 year duration, daily slices
        _setLinearTemplate(2, 0, 180 days, 7 days); // No cliff, 6 months, weekly slices
        _setLinearTemplate(3, 30 days, 730 days, 1 days); // 1 month cliff, 2 years, daily slices
        _setLinearTemplate(4, 0, 365 days, 0); // No cliff, 1 year, continuous
    }

    // ============ Modifiers ============

    modifier onlyPlanOwner(uint256 positionId) {
        require(ownerOf(positionId) == msg.sender, "Not position owner");
        _;
    }

    // ============ Owner Functions ============

    function setBaseTokenURI(string calldata newBaseTokenURI) external onlyOwner {
        baseTokenURI = newBaseTokenURI;
    }

    function toggleOnchainMetadata() external onlyOwner {
        useOnchainMetadata = !useOnchainMetadata;
        emit MetadataToggled(useOnchainMetadata);
    }

    function setMetadataUpdateInterval(uint256 interval) external onlyOwner {
        require(interval > 0, "Interval must be > 0");
        metadataUpdateInterval = interval;
        emit MetadataUpdateIntervalSet(interval);
    }

    function setLinearTemplate(
        uint256 templateId,
        uint256 cliff,
        uint256 duration,
        uint256 slice
    ) external onlyOwner {
        _setLinearTemplate(templateId, cliff, duration, slice);
    }

    function removeLinearTemplate(uint256 templateId) external onlyOwner {
        delete linearTemplates[templateId];
        emit LinearTemplateRemoved(templateId);
    }

    // ============ Public Functions ============

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
        require(linearTemplates[templateId].duration > 0, "Invalid template");

        LinearTemplate memory template = linearTemplates[templateId];
        
        // Store template params directly in plan for efficiency
        VestingPlan memory plan = VestingPlan({
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
            cliff: uint64(template.cliff),
            duration: uint64(template.duration),
            slice: uint64(template.slice)
        });

        positionId = nextPositionId++;
        plans[positionId] = plan;
        positionTokenIds[positionId] = tokenIds;

        // Handle permits and transfers
        _handlePermitsAndTransfers(sourceCollection, tokenIds, permits);

        // Initialize metadata update tracking
        lastMetadataUpdate[positionId] = block.number;

        _safeMint(beneficiary, positionId);

        emit LinearPlanCreated(positionId, beneficiary, sourceCollection, templateId, tokenIds);
        return positionId;
    }

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
        require(trancheSchedule.length > 0, "No tranches provided");
        _validateTranches(trancheSchedule, tokenIds.length);

        VestingPlan memory plan = VestingPlan({
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
            cliff: 0,
            duration: 0,
            slice: 0
        });

        positionId = nextPositionId++;
        plans[positionId] = plan;
        positionTokenIds[positionId] = tokenIds;
        tranches[positionId] = trancheSchedule;

        // Handle permits and transfers
        _handlePermitsAndTransfers(sourceCollection, tokenIds, permits);

        // Initialize metadata update tracking
        lastMetadataUpdate[positionId] = block.number;

        _safeMint(beneficiary, positionId);

        emit TranchePlanCreated(positionId, beneficiary, sourceCollection, tokenIds, trancheSchedule);
        return positionId;
    }

    function claim(
        uint256 positionId,
        address to,
        uint256[] calldata tokenIds
    ) external nonReentrant {
        VestingPlan storage plan = plans[positionId];
        require(!plan.revoked, "Plan has been revoked");
        require(ownerOf(positionId) == msg.sender || plan.beneficiary == msg.sender, "Not authorized");
        require(tokenIds.length > 0, "No tokens specified");

        uint256 unlockedAmount = _getUnlockedCount(positionId);
        require(plan.claimedCount + tokenIds.length <= unlockedAmount, "Not enough unlocked");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(!released[positionId][tokenIds[i]], "Token already released");
            released[positionId][tokenIds[i]] = true;
        }

        plan.claimedCount += tokenIds.length;

        // Transfer tokens to beneficiary
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(plan.sourceCollection).safeTransferFrom(address(this), to, tokenIds[i]);
        }

        emit Claimed(positionId, to, tokenIds);
    }

    function revoke(uint256 positionId) external nonReentrant {
        VestingPlan storage plan = plans[positionId];
        require(plan.issuer == msg.sender, "Not issuer");
        require(!plan.revoked, "Already revoked");

        plan.revoked = true;
        plan.revokeTime = block.timestamp;
        plan.vestedCapOnRevoke = _getUnlockedCount(positionId);

        // Return unvested tokens to issuer
        uint256[] memory unvestedTokens = new uint256[](plan.totalCount - plan.vestedCapOnRevoke);
        uint256 index = 0;
        
        for (uint256 i = 0; i < plan.totalCount; i++) {
            uint256 tokenId = positionTokenIds[positionId][i];
            if (!released[positionId][tokenId] && i >= plan.vestedCapOnRevoke) {
                unvestedTokens[index] = tokenId;
                index++;
            }
        }

        // Transfer unvested tokens back to issuer
        for (uint256 i = 0; i < index; i++) {
            IERC721(plan.sourceCollection).safeTransferFrom(address(this), plan.issuer, unvestedTokens[i]);
        }

        emit Revoked(positionId, plan.issuer, unvestedTokens);
    }

    function setCustomTokenURI(uint256 positionId, string calldata uri) external onlyPlanOwner(positionId) {
        require(bytes(uri).length > 0, "URI cannot be empty");
        customTokenURI[positionId] = uri;
        emit CustomTokenURISet(positionId, uri);
    }

    // ============ View Functions ============

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        
        if (bytes(customTokenURI[tokenId]).length > 0) {
            return customTokenURI[tokenId];
        }
        
        if (useOnchainMetadata) {
            return _generateDynamicMetadata(tokenId);
        }
        
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    function getPlan(uint256 positionId) external view returns (VestingPlan memory) {
        return plans[positionId];
    }

    function claimableCount(uint256 positionId) external view returns (uint256) {
        VestingPlan memory plan = plans[positionId];
        uint256 unlocked = _getUnlockedCount(positionId);
        return unlocked > plan.claimedCount ? unlocked - plan.claimedCount : 0;
    }

    function unlockedCount(uint256 positionId, uint256 timestamp) external view returns (uint256) {
        return _getUnlockedCountAtTime(positionId, timestamp);
    }

    // ============ Internal Functions ============

    function _setLinearTemplate(uint256 templateId, uint256 cliff, uint256 duration, uint256 slice) internal {
        require(cliff < duration, "Cliff must be less than duration");
        require(slice == 0 || slice <= duration, "Invalid slice");
        
        linearTemplates[templateId] = LinearTemplate({
            cliff: cliff,
            duration: duration,
            slice: slice
        });
        
        emit LinearTemplateSet(templateId, cliff, duration, slice);
    }

    function _validateTranches(Tranche[] calldata trancheSchedule, uint256 totalTokens) internal view {
        require(trancheSchedule[0].timestamp > block.timestamp, "First tranche must be in future");
        
        for (uint256 i = 1; i < trancheSchedule.length; i++) {
            require(trancheSchedule[i].timestamp > trancheSchedule[i-1].timestamp, "Tranches must be ordered");
            require(trancheSchedule[i].count > trancheSchedule[i-1].count, "Counts must increase");
        }
        
        require(trancheSchedule[trancheSchedule.length - 1].count <= totalTokens, "Total count exceeds tokens");
    }

    function _handlePermitsAndTransfers(
        address sourceCollection,
        uint256[] calldata tokenIds,
        PermitInput[] calldata permits
    ) internal {
        for (uint256 i = 0; i < permits.length; i++) {
            PermitInput memory permit = permits[i];
            if (permit.usePermit) {
                IERC4494(sourceCollection).permit(
                    address(this),
                    permit.tokenId,
                    permit.deadline,
                    permit.signature
                );
            }
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(sourceCollection).safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }
    }

    function _getUnlockedCount(uint256 positionId) internal view returns (uint256) {
        return _getUnlockedCountAtTime(positionId, block.timestamp);
    }

    function _getUnlockedCountAtTime(uint256 positionId, uint256 timestamp) internal view returns (uint256) {
        VestingPlan memory plan = plans[positionId];
        
        if (plan.isLinear) {
            return _getLinearUnlockedCount(positionId, timestamp);
        } else {
            return _getTrancheUnlockedCount(positionId, timestamp);
        }
    }

    function _getLinearUnlockedCount(uint256 positionId, uint256 timestamp) internal view returns (uint256) {
        VestingPlan memory plan = plans[positionId];
        
        if (timestamp <= plan.startTime) return 0;
        
        uint256 elapsed = timestamp - plan.startTime;
        if (elapsed < plan.cliff) return 0;
        if (elapsed >= plan.duration) return plan.totalCount;
        
        uint256 vestWindow = plan.duration - plan.cliff;
        uint256 effElapsed = elapsed - plan.cliff;
        
        if (plan.slice > 0) {
            effElapsed = (effElapsed / plan.slice) * plan.slice;
        }
        
        return (plan.totalCount * effElapsed) / vestWindow;
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

    function _generateDynamicMetadata(uint256 tokenId) internal view returns (string memory) {
        VestingPlan memory plan = plans[tokenId];
        
        // Check if metadata should be updated
        bool shouldUpdate = (block.number - lastMetadataUpdate[tokenId]) >= metadataUpdateInterval;
        
        // Get current vesting state
        uint256 unlockedNow = _getUnlockedCount(tokenId);
        uint256 remainingClaimable = unlockedNow > plan.claimedCount ? (unlockedNow - plan.claimedCount) : 0;
        uint256 nextUnlockTime = _getNextUnlockTime(tokenId);
        
        // Calculate progress percentage
        uint256 progressPercent = plan.totalCount > 0 ? (unlockedNow * 100) / plan.totalCount : 0;
        
        // Generate dynamic status
        string memory status;
        if (plan.revoked) {
            status = "Revoked";
        } else if (unlockedNow >= plan.totalCount) {
            status = "Fully Vested";
        } else if (unlockedNow > plan.claimedCount) {
            status = "Claimable";
        } else {
            status = "Vesting";
        }

        string memory json = string(
            abi.encodePacked(
                '{"name":"Vesting Position #',
                tokenId.toString(),
                '","description":"Dynamic NFT vesting position with real-time updating metadata. This NFT represents a vesting plan that escrows tokens from a source collection and unlocks them over time.",',
                '"attributes":[',
                '{"trait_type":"Status","value":"', status, '"},',
                '{"trait_type":"Schedule Type","value":"',
                plan.isLinear ? "Linear" : "Tranche",
                '"},',
                '{"trait_type":"Source Collection","value":"',
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
                remainingClaimable.toString(),
                '},',
                '{"trait_type":"Progress","value":"',
                progressPercent.toString(),
                '%"},',
                '{"trait_type":"Revocable","value":',
                plan.revoked ? "No" : "Yes",
                '},',
                '{"trait_type":"Revoked","value":',
                plan.revoked ? "Yes" : "No",
                '},',
                '{"trait_type":"Metadata Updated","value":"',
                shouldUpdate ? "Needs Update" : "Current",
                '},',
                '{"trait_type":"Blocks Since Update","value":',
                (block.number - lastMetadataUpdate[tokenId]).toString(),
                '}],',
                '"properties":{',
                '"nextUnlockTime":', nextUnlockTime.toString(), ',',
                '"startTime":', plan.startTime.toString(), ',',
                '"lastMetadataUpdate":', lastMetadataUpdate[tokenId].toString(), ',',
                '"currentBlock":', block.number.toString(),
                '}}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function _getNextUnlockTime(uint256 positionId) internal view returns (uint256) {
        VestingPlan memory plan = plans[positionId];
        
        if (plan.isLinear) {
            if (plan.revoked) return 0;
            
            uint256 startAfterCliff = plan.startTime + plan.cliff;
            if (block.timestamp < startAfterCliff) return startAfterCliff;
            
            if (plan.slice == 0) {
                if (block.timestamp >= plan.startTime + plan.duration) return 0;
                return block.timestamp;
            } else {
                uint256 end = plan.startTime + plan.duration;
                uint256 elapsedSinceCliff = block.timestamp - startAfterCliff;
                uint256 nextSlices = (elapsedSinceCliff / plan.slice + 1) * plan.slice;
                uint256 t = startAfterCliff + nextSlices;
                if (t >= end) {
                    return block.timestamp < end ? end : 0;
                }
                return t;
            }
        } else {
            if (plan.revoked) return 0;
            
            Tranche[] memory trancheSchedule = tranches[positionId];
            for (uint256 i = 0; i < trancheSchedule.length; i++) {
                if (block.timestamp < trancheSchedule[i].timestamp) {
                    return trancheSchedule[i].timestamp;
                }
            }
            return 0;
        }
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

    // ============ ERC721Receiver ============

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // ============ Constants ============

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
}
