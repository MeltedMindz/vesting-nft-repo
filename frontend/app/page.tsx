'use client'

import { ConnectButton } from '@rainbow-me/rainbowkit'
import { useAccount } from 'wagmi'
import { useState } from 'react'
import { Header } from '@/components/Header'
import { CreateVestingPlan } from '@/components/CreateVestingPlan'
import { VestingDashboard } from '@/components/VestingDashboard'
import { WalletNotConnected } from '@/components/WalletNotConnected'

export default function Home() {
  const { isConnected } = useAccount()
  const [activeTab, setActiveTab] = useState<'create' | 'dashboard'>('create')

  if (!isConnected) {
    return (
      <div className="min-h-screen bg-gray-50">
        <Header />
        <WalletNotConnected />
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Header />
      <main className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto">
          <div className="mb-8">
            <div className="flex space-x-1 bg-gray-100 p-1 rounded-lg w-fit">
              <button
                onClick={() => setActiveTab('create')}
                className={`px-4 py-2 rounded-md font-medium transition-colors ${
                  activeTab === 'create'
                    ? 'bg-white text-primary-600 shadow-sm'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                Create Vesting Plan
              </button>
              <button
                onClick={() => setActiveTab('dashboard')}
                className={`px-4 py-2 rounded-md font-medium transition-colors ${
                  activeTab === 'dashboard'
                    ? 'bg-white text-primary-600 shadow-sm'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                My Vesting Positions
              </button>
            </div>
          </div>

          {activeTab === 'create' && <CreateVestingPlan />}
          {activeTab === 'dashboard' && <VestingDashboard />}
        </div>
      </main>
    </div>
  )
}
