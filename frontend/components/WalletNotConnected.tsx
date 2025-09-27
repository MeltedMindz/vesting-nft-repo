'use client'

import { Wallet, ArrowRight } from 'lucide-react'

export function WalletNotConnected() {
  return (
    <div className="flex items-center justify-center min-h-[60vh]">
      <div className="text-center max-w-md mx-auto">
        <div className="bg-primary-100 rounded-full p-4 w-16 h-16 mx-auto mb-6 flex items-center justify-center">
          <Wallet className="h-8 w-8 text-primary-600" />
        </div>
        <h2 className="text-2xl font-bold text-gray-900 mb-4">
          Connect Your Wallet
        </h2>
        <p className="text-gray-600 mb-8">
          Connect your wallet to create and manage NFT vesting contracts. 
          You can create linear or tranche-based vesting plans for your NFTs.
        </p>
        <div className="flex items-center justify-center text-sm text-gray-500">
          <ArrowRight className="h-4 w-4 mr-2" />
          Click the "Connect Wallet" button above to get started
        </div>
      </div>
    </div>
  )
}
