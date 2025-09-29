# Vesting NFT Platform - Deployment Guide

## Overview

This guide covers deploying the Vesting NFT Platform, including smart contracts to Base network and the frontend to Vercel.

## Prerequisites

### Required Tools
- **Foundry**: For smart contract development and deployment
- **Node.js**: For frontend development
- **Git**: For version control
- **Web3 Wallet**: For deployment transactions

### Required Accounts
- **Base Network**: ETH for gas fees
- **Vercel Account**: For frontend deployment
- **BaseScan API Key**: For contract verification

## Smart Contract Deployment

### Environment Setup

1. **Install Foundry**:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

2. **Clone Repository**:
```bash
git clone https://github.com/MeltedMindz/vesting-nft-repo.git
cd vesting-nft-repo
```

3. **Install Dependencies**:
```bash
forge install
```

4. **Set Environment Variables**:
```bash
export PRIVATE_KEY="your_private_key_here"
export BASESCAN_API_KEY="I2BN462ZBJSUNDTFR66AUC49HZZKEZ8C5D"
```

### Deploying the Vesting Contract

1. **Deploy Dynamic Vesting Contract**:
```bash
forge script script/DeployDynamic.s.sol --rpc-url https://mainnet.base.org --broadcast --verify
```

2. **Verify Deployment**:
```bash
forge script script/TestDeployedDynamic.s.sol --rpc-url https://mainnet.base.org
```

### Deploying Test NFTs (Optional)

1. **Deploy Test NFT Contract**:
```bash
forge script script/MintTestNFTs.s.sol --rpc-url https://mainnet.base.org --broadcast --verify
```

2. **Mint Additional Test NFTs**:
```bash
forge script script/Mint200NFTs.s.sol --rpc-url https://mainnet.base.org --broadcast --verify
```

### Contract Addresses

After deployment, you'll have:
- **Vesting Contract**: `0xceAbAA1d992681A7A4F0923Ff21d3Cc1B5201688`
- **Test NFT Contract**: `0x8092D5f24E3da6C50F93B70dAf6A549061b127F3`

## Frontend Deployment

### Environment Configuration

1. **Update Environment Variables**:
```bash
cd frontend
cp env.example .env.local
```

2. **Configure `.env.local`**:
```bash
# WalletConnect Project ID
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id_here

# Contract Addresses
NEXT_PUBLIC_VESTING_CONTRACT_ADDRESS=0xceAbAA1d992681A7A4F0923Ff21d3Cc1B5201688
NEXT_PUBLIC_TEST_NFT_CONTRACT_ADDRESS=0x8092D5f24E3da6C50F93B70dAf6A549061b127F3

# BaseScan API Key
NEXT_PUBLIC_BASESCAN_API_KEY=I2BN462ZBJSUNDTFR66AUC49HZZKEZ8C5D

# RPC URLs
NEXT_PUBLIC_BASE_RPC_URL=https://mainnet.base.org
```

### Local Development

1. **Install Dependencies**:
```bash
npm install
```

2. **Run Development Server**:
```bash
npm run dev
```

3. **Build for Production**:
```bash
npm run build
```

### Vercel Deployment

1. **Connect to Vercel**:
   - Go to [vercel.com](https://vercel.com)
   - Connect your GitHub account
   - Import the repository

2. **Configure Build Settings**:
   - Framework Preset: Next.js
   - Root Directory: `frontend`
   - Build Command: `npm run build`
   - Output Directory: `.next`

3. **Set Environment Variables in Vercel**:
   ```
   NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id_here
   NEXT_PUBLIC_VESTING_CONTRACT_ADDRESS=0xceAbAA1d992681A7A4F0923Ff21d3Cc1B5201688
   NEXT_PUBLIC_TEST_NFT_CONTRACT_ADDRESS=0x8092D5f24E3da6C50F93B70dAf6A549061b127F3
   NEXT_PUBLIC_BASESCAN_API_KEY=I2BN462ZBJSUNDTFR66AUC49HZZKEZ8C5D
   NEXT_PUBLIC_BASE_RPC_URL=https://mainnet.base.org
   ```

4. **Deploy**:
   - Click "Deploy" in Vercel dashboard
   - Wait for deployment to complete
   - Your app will be available at the provided URL

### Manual Deployment

1. **Build and Deploy**:
```bash
cd frontend
npm run build
vercel --prod
```

2. **Update Environment Variables**:
```bash
vercel env add NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID
vercel env add NEXT_PUBLIC_VESTING_CONTRACT_ADDRESS
vercel env add NEXT_PUBLIC_TEST_NFT_CONTRACT_ADDRESS
vercel env add NEXT_PUBLIC_BASESCAN_API_KEY
vercel env add NEXT_PUBLIC_BASE_RPC_URL
```

## Contract Verification

### Automatic Verification
Contracts are automatically verified during deployment using:
```bash
forge script script/DeployDynamic.s.sol --rpc-url https://mainnet.base.org --broadcast --verify
```

### Manual Verification
If automatic verification fails:

1. **Generate Verification Command**:
```bash
forge script script/VerifyDynamic.s.sol --rpc-url https://mainnet.base.org
```

2. **Use BaseScan Web Interface**:
   - Go to [BaseScan](https://basescan.org)
   - Navigate to your contract address
   - Click "Verify and Publish"
   - Upload the flattened contract source code

### Flattened Contract
For manual verification, use the flattened contract:
```bash
forge flatten src/Vesting721Of721PlusDynamic.sol > Vesting721Of721PlusDynamic_flattened.sol
```

## Testing Deployment

### Smart Contract Testing

1. **Run Unit Tests**:
```bash
forge test
```

2. **Test Deployed Contract**:
```bash
forge script script/TestDeployedDynamic.s.sol --rpc-url https://mainnet.base.org
```

3. **Check Contract Status**:
```bash
forge script script/CheckSetup.s.sol --rpc-url https://mainnet.base.org
```

### Frontend Testing

1. **Local Testing**:
```bash
cd frontend
npm run dev
# Test at http://localhost:3000
```

2. **Production Testing**:
   - Visit your deployed Vercel URL
   - Test wallet connection
   - Test NFT selection
   - Test vesting plan creation

## Monitoring and Maintenance

### Contract Monitoring

1. **BaseScan Integration**:
   - Monitor contract interactions
   - Track transaction history
   - Monitor gas usage

2. **Event Monitoring**:
   - Track `LinearPlanCreated` events
   - Monitor `Claimed` events
   - Watch for `Revoked` events

### Frontend Monitoring

1. **Vercel Analytics**:
   - Monitor page views
   - Track user interactions
   - Monitor performance metrics

2. **Error Tracking**:
   - Monitor JavaScript errors
   - Track failed transactions
   - Monitor wallet connection issues

## Security Considerations

### Smart Contract Security
- Contracts are built on OpenZeppelin v5 (audited)
- Follow Solidity best practices
- Implement proper access controls
- Use reentrancy protection

### Frontend Security
- Validate all user inputs
- Use environment variables for sensitive data
- Implement proper error handling
- Secure API key management

### Deployment Security
- Use environment variables for private keys
- Never commit private keys to version control
- Use hardware wallets for mainnet deployments
- Implement proper access controls

## Troubleshooting

### Common Deployment Issues

#### Contract Deployment Fails
- Check gas limits
- Verify private key and balance
- Ensure RPC endpoint is working
- Check contract compilation

#### Frontend Build Fails
- Check Node.js version compatibility
- Verify all dependencies are installed
- Check for TypeScript errors
- Ensure environment variables are set

#### Verification Fails
- Use flattened contract source code
- Check constructor arguments format
- Verify compiler version matches
- Try manual verification on BaseScan

### Getting Help
- Check [Foundry Documentation](https://book.getfoundry.sh)
- Review [Next.js Deployment Guide](https://nextjs.org/docs/deployment)
- Consult [Vercel Documentation](https://vercel.com/docs)
- Check [Base Network Documentation](https://docs.base.org)

## Post-Deployment Checklist

### Smart Contracts
- [ ] Contract deployed successfully
- [ ] Contract verified on BaseScan
- [ ] All functions working correctly
- [ ] Events emitting properly
- [ ] Gas costs optimized

### Frontend
- [ ] Application deployed to Vercel
- [ ] Environment variables configured
- [ ] Wallet connection working
- [ ] Contract integration functional
- [ ] All features tested

### Documentation
- [ ] README updated with contract addresses
- [ ] API documentation complete
- [ ] User guide published
- [ ] Deployment guide updated

### Monitoring
- [ ] BaseScan integration active
- [ ] Vercel analytics enabled
- [ ] Error tracking configured
- [ ] Performance monitoring active

## Rollback Procedures

### Smart Contract Rollback
- Deploy new contract with fixes
- Update frontend to use new address
- Migrate any necessary data
- Update documentation

### Frontend Rollback
- Revert to previous Vercel deployment
- Update environment variables if needed
- Test functionality
- Communicate changes to users

---

**Deployment Complete!** Your Vesting NFT Platform is now live and ready for users.
