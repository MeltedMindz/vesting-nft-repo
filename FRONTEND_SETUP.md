# Frontend Setup Guide

This guide will help you set up and deploy the Vesting NFT frontend application.

## Prerequisites

Before starting, ensure you have:

- Node.js 18+ installed
- A deployed Vesting721Of721Plus smart contract
- A WalletConnect Project ID (get from [WalletConnect Cloud](https://cloud.walletconnect.com/))

## Quick Start

### 1. Install Dependencies

```bash
cd frontend
npm install
```

### 2. Configure Environment

Copy the example environment file:

```bash
cp env.example .env.local
```

Edit `.env.local` with your configuration:

```bash
# Get from https://cloud.walletconnect.com/
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id_here

# Your deployed contract address
NEXT_PUBLIC_VESTING_CONTRACT_ADDRESS=0x...

# Optional: Custom RPC URLs for better performance
NEXT_PUBLIC_MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/your-api-key
NEXT_PUBLIC_BASE_RPC_URL=https://mainnet.base.org
NEXT_PUBLIC_BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
```

### 3. Start Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to view the application.

## Deployment Options

### Option 1: Vercel (Recommended)

1. Install Vercel CLI:
```bash
npm i -g vercel
```

2. Deploy:
```bash
vercel --prod
```

3. Set environment variables in Vercel dashboard:
   - `NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID`
   - `NEXT_PUBLIC_VESTING_CONTRACT_ADDRESS`

### Option 2: Netlify

1. Build the project:
```bash
npm run build
```

2. Deploy to Netlify:
```bash
npx netlify deploy --prod --dir=out
```

### Option 3: Custom Server

1. Build the project:
```bash
npm run build
```

2. Start the production server:
```bash
npm start
```

## Features Overview

### 🎯 Core Functionality

- **Wallet Connection**: Connect with MetaMask, WalletConnect, and 50+ wallets
- **Linear Vesting**: Create gradual release schedules with templates
- **Tranche Vesting**: Custom milestone-based unlock schedules
- **NFT Selection**: Choose specific tokens to vest
- **Dashboard**: Manage all vesting positions
- **Real-time Updates**: Live transaction status and progress

### 🎨 User Interface

- **Modern Design**: Clean, professional interface
- **Responsive**: Works on desktop, tablet, and mobile
- **Accessible**: WCAG compliant design
- **Dark Mode Ready**: Easy to extend with dark theme

### 🔧 Technical Features

- **TypeScript**: Full type safety
- **Next.js 14**: Latest React framework
- **Tailwind CSS**: Utility-first styling
- **Wagmi/Viem**: Modern Ethereum integration
- **RainbowKit**: Beautiful wallet connection UI

## Configuration Details

### WalletConnect Setup

1. Go to [WalletConnect Cloud](https://cloud.walletconnect.com/)
2. Create a new project
3. Copy your Project ID
4. Add it to your `.env.local` file

### Contract Integration

The frontend integrates with your deployed Vesting721Of721Plus contract through:

- **Contract ABI**: Defined in `hooks/useVestingContract.ts`
- **Contract Address**: Set via `NEXT_PUBLIC_VESTING_CONTRACT_ADDRESS`
- **Network Support**: Ethereum, Base, and Base Sepolia

### Customization

#### Styling
- Edit `tailwind.config.js` for theme customization
- Modify `app/globals.css` for global styles
- Update component styles in individual files

#### Contract Integration
- Update the ABI in `hooks/useVestingContract.ts`
- Modify contract interaction logic as needed
- Add new contract functions to the hook

#### UI Components
- All components are in the `components/` directory
- Each component is self-contained and reusable
- Easy to modify or extend functionality

## Troubleshooting

### Common Issues

**Build Errors**
- Ensure all environment variables are set
- Check that Node.js version is 18+
- Clear `.next` directory and rebuild

**Wallet Connection Issues**
- Verify WalletConnect Project ID is correct
- Check that contract address is valid
- Ensure you're on the correct network

**Transaction Failures**
- Verify contract is deployed and accessible
- Check that user has sufficient gas
- Ensure NFTs are approved for transfer

### Getting Help

1. Check the browser console for errors
2. Verify environment variables are set correctly
3. Ensure the smart contract is deployed and accessible
4. Check network connectivity and RPC endpoints

## Development

### Project Structure

```
frontend/
├── app/                    # Next.js app directory
│   ├── globals.css        # Global styles
│   ├── layout.tsx         # Root layout
│   ├── page.tsx           # Home page
│   └── providers.tsx      # Web3 providers
├── components/            # React components
│   ├── Header.tsx         # Navigation
│   ├── CreateVestingPlan.tsx
│   ├── LinearVestingForm.tsx
│   ├── TrancheVestingForm.tsx
│   ├── NFTSelector.tsx
│   ├── VestingDashboard.tsx
│   └── VestingPositionCard.tsx
├── hooks/                 # Custom hooks
│   └── useVestingContract.ts
├── scripts/               # Deployment scripts
│   └── deploy.sh
└── package.json
```

### Adding New Features

1. Create new components in `components/`
2. Add contract interactions to `hooks/useVestingContract.ts`
3. Update the main page to include new features
4. Test thoroughly before deployment

## Security Considerations

- Never commit `.env.local` files
- Use environment variables for sensitive data
- Validate all user inputs
- Implement proper error handling
- Use HTTPS in production

## Performance Optimization

- Images are optimized automatically by Next.js
- CSS is purged in production builds
- JavaScript is minified and tree-shaken
- Static assets are cached appropriately

## Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## License

MIT License - see LICENSE file for details.
