'use client'

import { WagmiProvider } from 'wagmi'
import { mainnet, base, baseSepolia } from 'wagmi/chains'
import { RainbowKitProvider, getDefaultConfig } from '@rainbow-me/rainbowkit'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { http } from 'viem'
import '@rainbow-me/rainbowkit/styles.css'

// Custom Base chain with better RPC endpoints
const baseChain = {
  ...base,
  rpcUrls: {
    default: {
      http: [
        'https://mainnet.base.org',
        'https://base-mainnet.g.alchemy.com/v2/demo', // Alchemy public endpoint
        'https://base.publicnode.com',
        'https://base.blockpi.network/v1/rpc/public'
      ]
    },
    public: {
      http: [
        'https://mainnet.base.org',
        'https://base-mainnet.g.alchemy.com/v2/demo',
        'https://base.publicnode.com',
        'https://base.blockpi.network/v1/rpc/public'
      ]
    }
  }
}

const config = getDefaultConfig({
  appName: 'Vesting NFT Platform',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || '',
  chains: [mainnet, baseChain, baseSepolia],
  transports: {
    [mainnet.id]: http(),
    [baseChain.id]: http(),
    [baseSepolia.id]: http(),
  }
})

const queryClient = new QueryClient()

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  )
}
