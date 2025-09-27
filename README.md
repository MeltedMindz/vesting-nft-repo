# Vesting721Of721Plus

A production-ready Solidity contract that vests ERC-721 NFTs using position NFTs. Each position NFT represents a vesting plan that escrows tokenIds from a source ERC-721 collection and unlocks them over time according to configurable schedules.

## Overview

This contract implements a sophisticated NFT vesting system with the following key features:

- **Position NFTs**: Each vesting plan is represented by an ERC-721 position NFT
- **Linear Schedules**: Template-based linear vesting with cliff periods and slice intervals
- **Tranche Schedules**: Custom tranche-based vesting with multiple unlock points
- **Revocation Support**: Manual and automatic revocation with deterministic token return policies
- **On-chain Metadata**: Rich JSON metadata with vesting status and next unlock times
- **EIP-4494 Permits**: Signature-based token transfers without prior approval
- **Base Chain Support**: Optimized for Base mainnet (8453) and Base Sepolia (84532)

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Source NFT    │    │  Vesting721Of721 │    │  Position NFT   │
│   Collection    │◄───┤      Plus        │◄───┤   (ERC-721)     │
│   (ERC-721)     │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
   TokenIds escrowed      Vesting schedules      Beneficiary owns
   in contract            (Linear/Tranche)        position NFT
```

## How Vesting Works

### Discrete Count Unlocking

The contract unlocks NFTs based on **count** rather than specific token IDs. This means:

- A plan with 10 NFTs might unlock 3 NFTs after 30 days, 7 NFTs after 60 days, etc.
- The beneficiary can claim any unlocked, unreleased NFTs up to the current unlock count
- Token IDs are returned deterministically (smallest IDs first for claims, largest IDs first for revocations)

### Linear vs Tranche Schedules

**Linear Schedules:**
- Unlock tokens continuously over time
- Support cliff periods (no tokens unlock before cliff)
- Support slice intervals (tokens unlock in discrete chunks)
- Template-based for reusability

**Tranche Schedules:**
- Unlock tokens at specific timestamps
- Each tranche specifies a cumulative count
- Fully customizable unlock schedule
- Monotonic validation (timestamps and counts must be increasing)

### Revocation Policies

**Manual Revocation:**
- Issuer specifies exactly which tokens to return
- Must return exactly the unvested count
- Beneficiary keeps all previously claimed tokens

**Automatic Revocation:**
- Contract automatically determines which tokens to return
- Policy: Return largest unreleased token IDs
- Beneficiary keeps smallest token IDs up to vested cap
- Deterministic and gas-efficient

## Installation

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js (for linting and formatting)

### Setup

```bash
# Clone the repository
git clone <repository-url>
cd vesting-nft-repo

# Install dependencies
forge install openzeppelin/openzeppelin-contracts
forge install openzeppelin/openzeppelin-contracts-upgradeable

# Build contracts
forge build

# Run tests
forge test -vvv

# Format code
forge fmt

# Lint code
npm install -g solhint
solhint "src/**/*.sol"
```

## Usage

### Deployment

```bash
# Deploy to Base Sepolia
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url https://sepolia.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify

# Deploy to Base Mainnet
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

### Configuration

```bash
# Configure linear templates
forge script script/ConfigureTemplates.s.sol:ConfigureTemplatesScript \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -e VESTING_ADDRESS=0x...

# Create a linear plan
forge script script/CreateLinearPlan.s.sol:CreateLinearPlanScript \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -e VESTING_ADDRESS=0x... \
  -e SOURCE_COLLECTION=0x... \
  -e BENEFICIARY=0x... \
  -e TEMPLATE_ID=1

# Create a tranche plan
forge script script/CreateTranchePlan.s.sol:CreateTranchePlanScript \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -e VESTING_ADDRESS=0x... \
  -e SOURCE_COLLECTION=0x... \
  -e BENEFICIARY=0x...

# Auto-revoke a plan
forge script script/RevokeAuto.s.sol:RevokeAutoScript \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -e VESTING_ADDRESS=0x... \
  -e POSITION_ID=1

# Get plan details
forge script script/Utils.s.sol:UtilsScript \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  -e VESTING_ADDRESS=0x... \
  -e POSITION_ID=1
```

### Using with Cast

```bash
# Get plan details
cast call $VESTING_ADDRESS "getPlan(uint256)" 1

# Get unlocked count
cast call $VESTING_ADDRESS "unlockedCount(uint256,uint256)" 1 $(date +%s)

# Get claimable count
cast call $VESTING_ADDRESS "claimableCount(uint256)" 1

# Preview claimable IDs
cast call $VESTING_ADDRESS "previewClaimableIds(uint256,uint256)" 1 5

# Get token URI
cast call $VESTING_ADDRESS "tokenURI(uint256)" 1
```

## Contract Interface

### Core Functions

```solidity
// Create linear plan
function createLinearPlan(
    address beneficiary,
    address sourceCollection,
    uint256 templateId,
    uint256[] calldata tokenIds,
    PermitInput[] calldata permits
) external returns (uint256 positionId);

// Create tranche plan
function createTranchePlan(
    address beneficiary,
    address sourceCollection,
    uint256[] calldata tokenIds,
    Tranche[] calldata trancheSchedule,
    PermitInput[] calldata permits
) external returns (uint256 positionId);

// Claim unlocked tokens
function claim(
    uint256 positionId,
    address to,
    uint256[] calldata tokenIds
) external;

// Manual revocation
function revoke(
    uint256 positionId,
    uint256[] calldata returnTokenIds
) external;

// Automatic revocation
function revokeAuto(uint256 positionId) external;
```

### View Functions

```solidity
// Get plan details
function getPlan(uint256 positionId) external view returns (VestingPlan memory);

// Get unlocked count at timestamp
function unlockedCount(uint256 positionId, uint256 timestamp) external view returns (uint256);

// Get claimable count now
function claimableCount(uint256 positionId) external view returns (uint256);

// Preview claimable token IDs
function previewClaimableIds(uint256 positionId, uint256 limit) external view returns (uint256[] memory);

// Get next unlock time
function nextUnlockTime(uint256 positionId) external view returns (uint256);
```

## Metadata

The contract generates rich on-chain metadata for position NFTs:

```json
{
  "name": "Vesting Position #1",
  "description": "NFT vesting position that escrows tokens from a source collection and unlocks them over time.",
  "attributes": [
    {"trait_type": "Schedule Kind", "value": "Linear"},
    {"trait_type": "Asset", "value": "0x..."},
    {"trait_type": "Total NFTs", "value": "10"},
    {"trait_type": "Claimed", "value": "3"},
    {"trait_type": "Unlocked Now", "value": "5"},
    {"trait_type": "Remaining Claimable", "value": "2"},
    {"trait_type": "Revocable", "value": "Yes"},
    {"trait_type": "Revoked", "value": "No"}
  ],
  "properties": {
    "nextUnlockTime": "1640995200"
  }
}
```

## Security Considerations

### Reentrancy Protection
- All external functions use `ReentrancyGuard`
- No external calls after state changes
- Strict validation of inputs

### Access Control
- Only position owners can claim
- Only issuers can revoke
- Owner can configure templates and metadata settings

### Token Safety
- Released tokens are tracked to prevent double-claims
- Tokens are only burned when fully settled
- Strict validation of token ownership

### Limitations
- Delegation is not per-position (global only)
- Template IDs are not stored with plans (linear plans)
- Tranche details are not directly accessible via view functions

## Base Chain Specifics

### Network Configuration
- **Base Mainnet**: Chain ID 8453, RPC: https://mainnet.base.org
- **Base Sepolia**: Chain ID 84532, RPC: https://sepolia.base.org

### Gas Optimization
- Optimized for Base's gas pricing
- Efficient storage patterns
- Minimal external calls

### Verification
- Automatic verification on Basescan
- Supports both mainnet and testnet
- Environment variable configuration

## Testing

The test suite covers all major functionality:

```bash
# Run all tests
forge test -vvv

# Run specific test files
forge test --match-contract VestingLinear -vvv
forge test --match-contract VestingTranche -vvv
forge test --match-contract RevokeAndClaims -vvv
forge test --match-contract Metadata -vvv
forge test --match-contract Permit4494 -vvv

# Run with gas reporting
forge test --gas-report

# Run fuzz tests
forge test --fuzz-runs 1000
```

## Examples

### Example 1: Linear Vesting with Cliff

```solidity
// Create template: 3 month cliff, 12 month duration, 1 day slice
uint256 templateId = vesting.setLinearTemplate(90 days, 365 days, 1 days);

// Create plan
uint256[] memory tokenIds = [1, 2, 3, 4, 5];
PermitInput[] memory permits = new PermitInput[](5);
// ... populate permits

uint256 positionId = vesting.createLinearPlan(
    beneficiary,
    sourceCollection,
    templateId,
    tokenIds,
    permits
);
```

### Example 2: Tranche Vesting

```solidity
// Create tranche schedule
Tranche[] memory tranches = new Tranche[](3);
tranches[0] = Tranche(block.timestamp + 30 days, 2);  // 2 tokens after 30 days
tranches[1] = Tranche(block.timestamp + 60 days, 4);  // 4 tokens after 60 days
tranches[2] = Tranche(block.timestamp + 90 days, 5);  // 5 tokens after 90 days

uint256 positionId = vesting.createTranchePlan(
    beneficiary,
    sourceCollection,
    tokenIds,
    tranches,
    permits
);
```

### Example 3: Claiming Tokens

```solidity
// Get claimable tokens
uint256[] memory claimableIds = vesting.previewClaimableIds(positionId, 5);

// Claim tokens
vesting.claim(positionId, beneficiary, claimableIds);
```

### Example 4: Revocation

```solidity
// Manual revocation
uint256[] memory returnTokenIds = [4, 5]; // Return largest tokens
vesting.revoke(positionId, returnTokenIds);

// Automatic revocation
vesting.revokeAuto(positionId);
```

## Future Extensions

- **Delegation**: Per-position delegation support
- **Batch Operations**: Batch claiming and revocation
- **Advanced Schedules**: Custom unlock functions
- **Multi-Asset**: Support for multiple source collections
- **Governance**: DAO-controlled template management

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## Support

For questions and support:
- Open an issue on GitHub
- Check the test files for usage examples
- Review the script files for deployment patterns
