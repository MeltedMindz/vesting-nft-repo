# Vesting NFT Platform API Documentation

## Overview

The Vesting NFT Platform provides a comprehensive API for interacting with vesting contracts on the Base blockchain. This document covers the smart contract functions, frontend APIs, and integration examples.

## Smart Contract API

### Contract Address
```
0xceAbAA1d992681A7A4F0923Ff21d3Cc1B5201688
```

### Core Functions

#### `createLinearPlan`
Creates a linear vesting plan using predefined templates.

```solidity
function createLinearPlan(
    address beneficiary,
    address sourceCollection,
    uint256 templateId,
    uint256[] calldata tokenIds,
    PermitInput[] calldata permits
) external nonReentrant returns (uint256 positionId)
```

**Parameters:**
- `beneficiary`: Address that will receive the vested NFTs
- `sourceCollection`: Contract address of the NFT collection to vest
- `templateId`: ID of the linear template to use (1-4)
- `tokenIds`: Array of token IDs to vest
- `permits`: Array of EIP-4494 permit inputs (can be empty)

**Returns:**
- `positionId`: Unique identifier for the created vesting plan

**Events:**
- `LinearPlanCreated(positionId, beneficiary, sourceCollection, templateId, tokenIds)`

#### `createTranchePlan`
Creates a custom tranche-based vesting plan.

```solidity
function createTranchePlan(
    address beneficiary,
    address sourceCollection,
    uint256[] calldata tokenIds,
    Tranche[] calldata trancheSchedule,
    PermitInput[] calldata permits
) external nonReentrant returns (uint256 positionId)
```

**Parameters:**
- `beneficiary`: Address that will receive the vested NFTs
- `sourceCollection`: Contract address of the NFT collection to vest
- `tokenIds`: Array of token IDs to vest
- `trancheSchedule`: Array of tranche milestones
- `permits`: Array of EIP-4494 permit inputs (can be empty)

**Tranche Structure:**
```solidity
struct Tranche {
    uint256 timestamp; // Unix timestamp when this tranche unlocks
    uint256 count;     // Cumulative count of tokens unlocked
}
```

#### `claim`
Claims vested NFTs from a position.

```solidity
function claim(
    uint256 positionId,
    address to,
    uint256[] calldata tokenIds
) external nonReentrant
```

**Parameters:**
- `positionId`: ID of the vesting position
- `to`: Address to receive the claimed NFTs
- `tokenIds`: Array of specific token IDs to claim

**Events:**
- `Claimed(positionId, to, tokenIds)`

#### `revoke`
Revokes a vesting plan (issuer only).

```solidity
function revoke(uint256 positionId) external nonReentrant
```

**Parameters:**
- `positionId`: ID of the vesting position to revoke

**Events:**
- `Revoked(positionId, issuer, returnedTokenIds)`

### View Functions

#### `getPlan`
Returns detailed information about a vesting plan.

```solidity
function getPlan(uint256 positionId) external view returns (VestingPlan memory)
```

**Returns VestingPlan struct:**
```solidity
struct VestingPlan {
    address sourceCollection;
    address beneficiary;
    address issuer;
    uint256 startTime;
    uint256 totalCount;
    uint256 claimedCount;
    bool isLinear;
    bool revoked;
    uint256 revokeTime;
    uint256 vestedCapOnRevoke;
    uint64 cliff;
    uint64 duration;
    uint64 slice;
}
```

#### `claimableCount`
Returns the number of NFTs that can be claimed from a position.

```solidity
function claimableCount(uint256 positionId) external view returns (uint256)
```

#### `unlockedCount`
Returns the number of NFTs unlocked at a specific timestamp.

```solidity
function unlockedCount(uint256 positionId, uint256 timestamp) external view returns (uint256)
```

#### `tokenURI`
Returns the metadata URI for a position NFT (includes dynamic metadata).

```solidity
function tokenURI(uint256 tokenId) external view returns (string memory)
```

### Template Functions

#### `linearTemplates`
Returns information about a linear template.

```solidity
function linearTemplates(uint256 templateId) external view returns (
    uint256 cliff,
    uint256 duration,
    uint256 slice
)
```

**Available Templates:**
1. Template 1: 90-day cliff, 365-day duration, daily slices
2. Template 2: No cliff, 180-day duration, weekly slices
3. Template 3: 30-day cliff, 730-day duration, daily slices
4. Template 4: No cliff, 365-day duration, continuous

## Frontend API

### React Hooks

#### `useVestingContract`
Custom hook for interacting with the vesting contract.

```typescript
const {
  createLinearPlan,
  createTranchePlan,
  claim,
  revoke,
  fetchUserVestingPositions,
  isLoading,
  error
} = useVestingContract()
```

**Functions:**
- `createLinearPlan(params)`: Create a linear vesting plan
- `createTranchePlan(params)`: Create a tranche vesting plan
- `claim(positionId, to, tokenIds)`: Claim vested NFTs
- `revoke(positionId)`: Revoke a vesting plan
- `fetchUserVestingPositions()`: Fetch user's vesting positions

### NFT Management

#### `NFTSelector`
Component for selecting NFTs to vest.

```typescript
interface NFTSelectorProps {
  selectedNFTs: number[]
  setSelectedNFTs: (nfts: number[]) => void
  sourceCollection: string
  setSourceCollection: (address: string) => void
}
```

**Features:**
- Bulk selection with range buttons
- Select all/deselect all functionality
- Visual NFT grid with selection indicators
- Support for 300 test NFTs (1-300)

### Vesting Forms

#### `LinearVestingForm`
Form for creating linear vesting plans.

```typescript
interface LinearVestingFormProps {
  selectedNFTs: number[]
  sourceCollection: string
}
```

#### `TrancheVestingForm`
Form for creating tranche vesting plans.

```typescript
interface TrancheVestingFormProps {
  selectedNFTs: number[]
  sourceCollection: string
}
```

## BaseScan API Integration

### Contract Verification
The platform integrates with BaseScan API for enhanced functionality:

```typescript
const BASESCAN_API_KEY = "I2BN462ZBJSUNDTFR66AUC49HZZKEZ8C5D"
const CONTRACT_ADDRESS = "0xceAbAA1d992681A7A4F0923Ff21d3Cc1B5201688"
```

### API Endpoints
- Contract verification status
- Transaction monitoring
- Enhanced metadata fetching
- Real-time contract interaction

## Integration Examples

### Creating a Linear Vesting Plan

```typescript
import { useVestingContract } from '@/hooks/useVestingContract'

const { createLinearPlan } = useVestingContract()

const handleCreateLinear = async () => {
  try {
    const positionId = await createLinearPlan({
      beneficiary: "0x...",
      sourceCollection: "0x8092D5f24E3da6C50F93B70dAf6A549061b127F3",
      templateId: 1,
      tokenIds: [201, 202, 203],
      permits: []
    })
    console.log("Created position:", positionId)
  } catch (error) {
    console.error("Error creating plan:", error)
  }
}
```

### Creating a Tranche Vesting Plan

```typescript
const handleCreateTranche = async () => {
  const tranches = [
    { timestamp: Math.floor(Date.now() / 1000) + 86400 * 30, count: 1 }, // 1 NFT after 30 days
    { timestamp: Math.floor(Date.now() / 1000) + 86400 * 90, count: 3 }, // 3 NFTs after 90 days
    { timestamp: Math.floor(Date.now() / 1000) + 86400 * 180, count: 5 } // 5 NFTs after 180 days
  ]
  
  try {
    const positionId = await createTranchePlan({
      beneficiary: "0x...",
      sourceCollection: "0x8092D5f24E3da6C50F93B70dAf6A549061b127F3",
      tokenIds: [201, 202, 203, 204, 205],
      trancheSchedule: tranches,
      permits: []
    })
    console.log("Created position:", positionId)
  } catch (error) {
    console.error("Error creating plan:", error)
  }
}
```

### Fetching User Positions

```typescript
const { fetchUserVestingPositions } = useVestingContract()

const loadPositions = async () => {
  try {
    const positions = await fetchUserVestingPositions()
    console.log("User positions:", positions)
  } catch (error) {
    console.error("Error fetching positions:", error)
  }
}
```

## Error Handling

### Common Errors
- `"Invalid beneficiary"`: Beneficiary address is zero address
- `"Invalid source collection"`: Source collection address is zero address
- `"No tokens provided"`: Empty tokenIds array
- `"Invalid template"`: Template ID doesn't exist
- `"Not enough unlocked"`: Trying to claim more than available
- `"Plan has been revoked"`: Attempting to interact with revoked plan

### Error Response Format
```typescript
interface ErrorResponse {
  message: string
  code?: number
  details?: any
}
```

## Rate Limiting

The platform implements rate limiting protection:
- Automatic retry logic for RPC calls
- Delays between batch operations
- Fallback mechanisms for high-load scenarios

## Testing

### Test NFT Contract
- **Address**: `0x8092D5f24E3da6C50F93B70dAf6A549061b127F3`
- **Total Supply**: 300 NFTs
- **Test Range**: Tokens 201-300 available for vesting

### Test Scenarios
1. Linear vesting with different templates
2. Custom tranche schedules
3. Claiming functionality
4. Revocation scenarios
5. Dynamic metadata updates

## Security Considerations

- Always verify contract addresses
- Check approval status before creating plans
- Validate beneficiary addresses
- Monitor gas fees for large operations
- Use proper error handling for all transactions
