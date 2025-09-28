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
      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
        <Header />
        <WalletNotConnected />
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
      <Header />
      <main className="container mx-auto px-4 py-8">
        <div className="max-w-6xl mx-auto">
          <div className="mb-8">
            <div className="flex space-x-1 bg-slate-800/50 backdrop-blur-sm border border-slate-700/50 p-1 rounded-xl w-fit">
              <button
                onClick={() => setActiveTab('create')}
                className={`px-6 py-3 rounded-lg font-medium transition-all duration-200 ${
                  activeTab === 'create'
                    ? 'bg-white text-slate-900 shadow-lg shadow-purple-500/25'
                    : 'text-slate-300 hover:text-white hover:bg-slate-700/50'
                }`}
              >
                Create Vesting Plan
              </button>
              <button
                onClick={() => setActiveTab('dashboard')}
                className={`px-6 py-3 rounded-lg font-medium transition-all duration-200 ${
                  activeTab === 'dashboard'
                    ? 'bg-white text-slate-900 shadow-lg shadow-purple-500/25'
                    : 'text-slate-300 hover:text-white hover:bg-slate-700/50'
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
