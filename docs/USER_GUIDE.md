# Vesting NFT Platform - User Guide

## Welcome to the Vesting NFT Platform

This guide will walk you through using the Vesting NFT Platform to create and manage NFT vesting schedules on the Base blockchain.

## Getting Started

### Prerequisites
Before you begin, make sure you have:
- A Web3 wallet (MetaMask, WalletConnect, etc.)
- Base network added to your wallet
- Some ETH on Base for gas fees
- NFTs you want to vest (or use our test NFTs)

### Connecting Your Wallet
1. Visit the [Vesting Platform](https://vesting-nft-app.vercel.app)
2. Click "Connect Wallet" in the top right
3. Select your preferred wallet
4. Approve the connection request
5. Make sure you're connected to the Base network

## Understanding Vesting

### What is NFT Vesting?
NFT vesting is a mechanism that locks NFTs in a smart contract and gradually releases them over time according to a predefined schedule. This is useful for:
- Employee token grants
- Investment lock-ups
- Gradual token releases
- Custom distribution schedules

### How It Works
1. **Create a Plan**: You select NFTs and define a vesting schedule
2. **Lock NFTs**: The selected NFTs are transferred to the vesting contract
3. **Receive Position NFT**: You get a Position NFT representing your vesting plan
4. **Gradual Release**: NFTs unlock over time according to your schedule
5. **Claim NFTs**: You can claim unlocked NFTs as they become available

## Creating Your First Vesting Plan

### Step 1: Select NFTs
1. Navigate to the "Create Vesting Plan" section
2. In the NFT Selector:
   - Enter the contract address of your NFT collection
   - Or use our test NFT contract: `0x8092D5f24E3da6C50F93B70dAf6A549061b127F3`
3. Select the NFTs you want to vest:
   - Click individual NFTs to select/deselect them
   - Use "Select All" to select all available NFTs
   - Use range buttons (1-10, 11-20, etc.) for bulk selection

### Step 2: Choose Vesting Type

#### Linear Vesting
Linear vesting releases tokens gradually over time using predefined templates:

**Template 1: 3 Month Cliff, 12 Month Duration**
- 90-day cliff period (no tokens unlock initially)
- 365-day total duration
- Daily release slices after cliff

**Template 2: 6 Month Duration, Weekly Release**
- No cliff period
- 180-day total duration
- Weekly release slices

**Template 3: 1 Month Cliff, 24 Month Duration**
- 30-day cliff period
- 730-day total duration
- Daily release slices after cliff

**Template 4: 1 Year Continuous**
- No cliff period
- 365-day total duration
- Continuous release (no slices)

#### Tranche Vesting
Tranche vesting allows custom milestone-based releases:
- Define specific unlock dates
- Set how many tokens unlock at each milestone
- Create complex, multi-stage release schedules

### Step 3: Configure Your Plan
1. **Beneficiary Address**: Enter the address that will receive the vested NFTs
2. **Template Selection**: Choose the appropriate template (for linear vesting)
3. **Review Details**: Check the summary of your vesting plan

### Step 4: Create the Plan
1. Click "Create Linear Plan" or "Create Tranche Plan"
2. Approve the NFT transfer in your wallet
3. Confirm the transaction
4. Wait for confirmation

## Managing Your Vesting Plans

### Viewing Your Positions
1. Go to the "My Vesting Positions" dashboard
2. View all your active vesting plans
3. Each plan is represented by a Position NFT with:
   - Current vesting status
   - Progress percentage
   - Claimable amount
   - Next unlock time

### Understanding Position NFT Metadata
Your Position NFT contains dynamic metadata that updates every 50 blocks:

**Status Types:**
- **Vesting**: Plan is active, tokens are gradually unlocking
- **Claimable**: You have tokens ready to claim
- **Fully Vested**: All tokens have unlocked
- **Revoked**: Plan has been revoked by issuer

**Metadata Information:**
- Schedule type (Linear or Tranche)
- Source collection address
- Total NFTs in the plan
- Claimed and remaining amounts
- Progress percentage
- Next unlock time
- Metadata update status

### Claiming Vested NFTs
1. In your Position NFT details, check the "Claimable" amount
2. If you have claimable NFTs:
   - Click "Claim" button
   - Select which specific NFTs to claim
   - Confirm the transaction
   - NFTs will be transferred to your wallet

### Monitoring Progress
- Position NFTs update automatically every 50 blocks
- Check the progress percentage to see vesting completion
- View next unlock time for upcoming releases
- Monitor claimable amounts regularly

## Advanced Features

### Custom Token URIs
If you own a Position NFT, you can set a custom metadata URI:
1. Go to your Position NFT details
2. Click "Set Custom URI"
3. Enter your custom metadata URL
4. Confirm the transaction

### Revocation (Issuer Only)
If you created a vesting plan, you can revoke it:
1. Go to your created positions
2. Click "Revoke Plan"
3. Confirm the revocation
4. Unvested NFTs will be returned to you

### EIP-4494 Permits
For gasless approvals, you can use EIP-4494 permits:
1. Sign a permit message instead of paying gas for approval
2. Include the permit signature when creating vesting plans
3. Reduce gas costs for large NFT transfers

## Troubleshooting

### Common Issues

#### "Wallet Not Connected"
- Make sure your wallet is connected
- Check that you're on the Base network
- Refresh the page if needed

#### "Insufficient Balance"
- Ensure you have enough ETH for gas fees
- Check that you own the NFTs you're trying to vest

#### "Transaction Failed"
- Check your gas limit settings
- Ensure you have enough ETH for gas
- Try increasing gas limit if transaction fails

#### "NFT Not Approved"
- The contract will request approval to transfer your NFTs
- Approve the transaction in your wallet
- For multiple NFTs, you may need to approve the entire collection

### Getting Help
1. Check transaction details on [BaseScan](https://basescan.org)
2. Verify you're using the correct contract address
3. Ensure you're on the Base network
4. Check that you have sufficient gas fees

## Best Practices

### Security
- Always verify contract addresses
- Double-check beneficiary addresses
- Review transaction details before confirming
- Keep your private keys secure

### Gas Optimization
- Batch multiple NFT selections when possible
- Use EIP-4494 permits for gasless approvals
- Claim tokens in batches rather than individually
- Monitor gas prices for optimal transaction timing

### Planning Your Vesting
- Consider the total duration and cliff periods
- Plan for the beneficiary's needs
- Test with small amounts first
- Document your vesting schedules

## Test Environment

### Test NFTs
The platform includes 300 test NFTs for experimentation:
- **Tokens 1-100**: Original test set
- **Tokens 101-200**: Additional test set  
- **Tokens 201-300**: Latest test set (recommended for testing)

### Test Contract Address
```
0x8092D5f24E3da6C50F93B70dAf6A549061b127F3
```

### Testing Workflow
1. Use test NFTs (201-300) for initial testing
2. Create small vesting plans first
3. Test claiming functionality
4. Experiment with different templates
5. Try tranche vesting with custom schedules

## Support and Resources

### Useful Links
- [Platform Frontend](https://vesting-nft-app.vercel.app)
- [Contract on BaseScan](https://basescan.org/address/0xceabaa1d992681a7a4f0923ff21d3cc1b5201688)
- [Base Network Documentation](https://docs.base.org)
- [GitHub Repository](https://github.com/MeltedMindz/vesting-nft-repo)

### Getting Help
- Check the [API Documentation](API.md) for technical details
- Review [Main Documentation](README.md) for overview
- Visit BaseScan for transaction details
- Check Base network status if experiencing issues

## Frequently Asked Questions

### Q: Can I modify a vesting plan after creation?
A: No, vesting plans cannot be modified once created. You would need to revoke the existing plan and create a new one.

### Q: What happens if I lose my Position NFT?
A: The Position NFT represents ownership of the vesting plan. If lost, you may not be able to claim vested tokens. Keep your NFTs secure.

### Q: Can I create vesting plans for other people?
A: Yes, you can set any address as the beneficiary when creating a vesting plan.

### Q: How often does the metadata update?
A: Position NFT metadata updates automatically every 50 blocks on the Base network.

### Q: Can I claim partial amounts?
A: Yes, you can claim any number of unlocked NFTs up to the claimable amount.

### Q: What's the difference between linear and tranche vesting?
A: Linear vesting uses predefined templates with gradual releases, while tranche vesting allows custom milestone-based schedules.

---

**Ready to start vesting?** Visit the [Vesting Platform](https://vesting-nft-app.vercel.app) and create your first vesting plan!
