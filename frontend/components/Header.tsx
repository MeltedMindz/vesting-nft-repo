'use client'

import { ConnectButton } from '@rainbow-me/rainbowkit'
import { Lock } from 'lucide-react'

export function Header() {
  return (
    <header className="bg-white shadow-sm border-b">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center space-x-2">
            <Lock className="h-8 w-8 text-primary-600" />
            <h1 className="text-xl font-bold text-gray-900">Vesting NFT Platform</h1>
          </div>
          <ConnectButton />
        </div>
      </div>
    </header>
  )
}
