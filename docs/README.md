# Vesting NFT Platform Documentation

## Overview

The Vesting NFT Platform is a comprehensive solution for creating and managing NFT vesting schedules on the Base blockchain. It allows users to lock NFTs in vesting contracts and gradually release them over time according to predefined schedules.

## Features

### 🎯 Core Functionality
- **Linear Vesting**: Gradual release over time with optional cliff periods
- **Tranche Vesting**: Custom milestone-based releases
- **Dynamic Metadata**: Real-time updating NFT metadata showing vesting progress
- **Position NFTs**: Each vesting plan is represented by an ERC-721 NFT
- **Revocation**: Issuers can revoke vesting plans under certain conditions

### 🔧 Technical Features
- **Base Network**: Deployed and verified on Base mainnet
- **OpenZeppelin Integration**: Built on proven, audited smart contract libraries
- **EIP-4494 Support**: Signature-based token transfers without prior approval
- **Gas Optimized**: Efficient contract design with optimized gas usage
- **Dynamic Updates**: Metadata updates every 50 blocks for real-time information

## Contract Addresses

### Main Contracts
- **Vesting Contract (Dynamic)**: `0xceAbAA1d992681A7A4F0923Ff21d3Cc1B5201688`
- **Test NFT Contract**: `0x8092D5f24E3da6C50F93B70dAf6A549061b127F3`

### Network Information
- **Network**: Base Mainnet
- **Chain ID**: 8453
- **RPC URL**: https://mainnet.base.org
- **Block Explorer**: https://basescan.org

## Getting Started

### Prerequisites
- MetaMask or compatible Web3 wallet
- Base network configured in your wallet
- Some ETH on Base for gas fees
- NFTs to vest (or use our test NFTs)

### Quick Start
1. Visit the [Vesting Platform](https://vesting-nft-app.vercel.app)
2. Connect your wallet to Base network
3. Select NFTs to vest
4. Choose vesting schedule (Linear or Tranche)
5. Create vesting plan
6. Monitor progress through position NFTs

## Vesting Types

### Linear Vesting
Linear vesting releases tokens gradually over time according to predefined templates:

#### Available Templates
1. **3 Month Cliff, 12 Month Duration**
   - Cliff: 90 days
   - Duration: 365 days
   - Slice: Daily releases

2. **6 Month Duration, Weekly Release**
   - Cliff: None
   - Duration: 180 days
   - Slice: Weekly releases

3. **1 Month Cliff, 24 Month Duration**
   - Cliff: 30 days
   - Duration: 730 days
   - Slice: Daily releases

4. **1 Year Continuous**
   - Cliff: None
   - Duration: 365 days
   - Slice: Continuous

### Tranche Vesting
Tranche vesting allows custom milestone-based releases:
- Define specific unlock dates
- Set cumulative token counts for each milestone
- Flexible scheduling for complex vesting needs

## Position NFTs

Each vesting plan creates a Position NFT that:
- Represents ownership of the vesting plan
- Contains dynamic metadata with real-time vesting status
- Updates automatically every 50 blocks
- Shows vesting progress, claimable amounts, and next unlock times

### Dynamic Metadata
The Position NFTs include:
- Current vesting status (Vesting, Claimable, Fully Vested, Revoked)
- Schedule type (Linear or Tranche)
- Source collection address
- Total NFTs in the plan
- Claimed and remaining claimable amounts
- Progress percentage
- Next unlock time
- Metadata update status

## Smart Contract Functions

### Core Functions
- `createLinearPlan()`: Create a linear vesting plan
- `createTranchePlan()`: Create a tranche vesting plan
- `claim()`: Claim vested NFTs
- `revoke()`: Revoke a vesting plan (issuer only)

### View Functions
- `getPlan()`: Get detailed plan information
- `claimableCount()`: Get number of claimable NFTs
- `unlockedCount()`: Get number of unlocked NFTs at specific time
- `tokenURI()`: Get dynamic metadata URI

### Owner Functions
- `setLinearTemplate()`: Set new linear templates
- `removeLinearTemplate()`: Remove linear templates
- `setMetadataUpdateInterval()`: Adjust metadata update frequency
- `toggleOnchainMetadata()`: Enable/disable dynamic metadata

## Gas Optimization

The contract includes several gas optimizations:
- Packed structs for efficient storage
- Batch operations for multiple NFTs
- Optimized metadata generation
- Efficient unlock calculations

## Security Features

### Access Control
- Owner-only functions for contract administration
- Issuer-only revocation capabilities
- Beneficiary-only claiming rights
- Position owner permissions for custom URIs

### Validation
- Input validation for all parameters
- Tranche schedule validation
- Template parameter validation
- Reentrancy protection

### Audit Status
- Built on OpenZeppelin v5 (audited)
- Follows Solidity best practices
- Gas-optimized implementations
- Comprehensive test coverage

## API Integration

### BaseScan API
The platform integrates with BaseScan API for:
- Contract verification status
- Transaction monitoring
- Enhanced metadata fetching
- Real-time contract interaction

### API Key Configuration
Set the following environment variables:
```bash
NEXT_PUBLIC_BASESCAN_API_KEY=your_api_key_here
NEXT_PUBLIC_VESTING_CONTRACT_ADDRESS=0xceAbAA1d992681A7A4F0923Ff21d3Cc1B5201688
```

## Testing

### Test NFTs
The platform includes a test NFT contract with 300 tokens:
- Tokens 1-100: Original test set
- Tokens 101-200: Additional test set
- Tokens 201-300: Latest test set for comprehensive testing

### Test Scenarios
1. Create linear vesting plans with different templates
2. Create custom tranche vesting schedules
3. Test claiming functionality
4. Test revocation scenarios
5. Verify dynamic metadata updates

## Troubleshooting

### Common Issues
1. **Wallet Connection**: Ensure you're connected to Base network
2. **Gas Fees**: Make sure you have sufficient ETH for transactions
3. **NFT Ownership**: Verify you own the NFTs you're trying to vest
4. **Approvals**: The contract will request approval to transfer your NFTs

### Support
- Check the [BaseScan contract page](https://basescan.org/address/0xceabaa1d992681a7a4f0923ff21d3cc1b5201688)
- Review transaction logs for detailed error information
- Ensure you're using the latest version of the frontend

## Development

### Local Development
1. Clone the repository
2. Install dependencies: `npm install`
3. Set up environment variables
4. Run development server: `npm run dev`

### Contract Development
1. Install Foundry: `curl -L https://foundry.paradigm.xyz | bash`
2. Install dependencies: `forge install`
3. Run tests: `forge test`
4. Deploy contracts: `forge script script/Deploy.s.sol`

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Links

- **Frontend**: https://vesting-nft-app.vercel.app
- **Contract**: https://basescan.org/address/0xceabaa1d992681a7a4f0923ff21d3cc1b5201688
- **GitHub**: https://github.com/MeltedMindz/vesting-nft-repo
- **Base Network**: https://base.org
