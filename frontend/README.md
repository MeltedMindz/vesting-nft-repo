# Vesting NFT Frontend

A modern React frontend for the Vesting721Of721Plus smart contract, built with Next.js, TypeScript, and Tailwind CSS.

## Features

- 🔗 **Wallet Connection**: Connect with MetaMask, WalletConnect, and other popular wallets
- 📊 **Linear Vesting**: Create linear vesting plans with configurable templates
- 📅 **Tranche Vesting**: Create custom tranche-based vesting schedules
- 🎨 **NFT Selection**: Choose NFTs from your collections to vest
- 📱 **Responsive Design**: Works on desktop and mobile devices
- ⚡ **Real-time Updates**: Live transaction status and vesting progress

## Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn
- A deployed Vesting721Of721Plus contract
- WalletConnect Project ID

### Installation

1. Install dependencies:
```bash
npm install
```

2. Copy the environment file:
```bash
cp env.example .env.local
```

3. Configure your environment variables:
```bash
# Get a WalletConnect Project ID from https://cloud.walletconnect.com/
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id_here

# Set your deployed contract address
NEXT_PUBLIC_VESTING_CONTRACT_ADDRESS=0x...
```

4. Start the development server:
```bash
npm run dev
```

5. Open [http://localhost:3000](http://localhost:3000) in your browser.

## Configuration

### Contract Address

Set the `NEXT_PUBLIC_VESTING_CONTRACT_ADDRESS` environment variable to your deployed Vesting721Of721Plus contract address.

### WalletConnect

1. Go to [WalletConnect Cloud](https://cloud.walletconnect.com/)
2. Create a new project
3. Copy your Project ID
4. Set it in your `.env.local` file

### Custom RPC URLs

You can optionally set custom RPC URLs for better performance:

```bash
NEXT_PUBLIC_MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/your-api-key
NEXT_PUBLIC_BASE_RPC_URL=https://mainnet.base.org
NEXT_PUBLIC_BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
```

## Usage

### Creating Linear Vesting Plans

1. Connect your wallet
2. Select "Create Vesting Plan"
3. Choose "Linear Vesting"
4. Enter the source collection address
5. Select NFTs to vest
6. Choose a beneficiary address
7. Select a vesting template
8. Create the plan

### Creating Tranche Vesting Plans

1. Connect your wallet
2. Select "Create Vesting Plan"
3. Choose "Tranche Vesting"
4. Enter the source collection address
5. Select NFTs to vest
6. Choose a beneficiary address
7. Configure tranche schedule with dates and amounts
8. Create the plan

### Managing Vesting Positions

1. Go to "My Vesting Positions"
2. View all your vesting plans
3. Filter by type (Linear/Tranche)
4. Claim unlocked tokens
5. Monitor progress

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
│   ├── Header.tsx         # Navigation header
│   ├── CreateVestingPlan.tsx
│   ├── LinearVestingForm.tsx
│   ├── TrancheVestingForm.tsx
│   ├── NFTSelector.tsx
│   ├── VestingDashboard.tsx
│   └── VestingPositionCard.tsx
├── hooks/                 # Custom React hooks
│   └── useVestingContract.ts
└── package.json
```

### Key Technologies

- **Next.js 14**: React framework with app directory
- **TypeScript**: Type-safe JavaScript
- **Tailwind CSS**: Utility-first CSS framework
- **Wagmi**: React hooks for Ethereum
- **Viem**: TypeScript interface for Ethereum
- **RainbowKit**: Wallet connection UI
- **Lucide React**: Beautiful icons

### Building for Production

```bash
npm run build
npm start
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see LICENSE file for details.
