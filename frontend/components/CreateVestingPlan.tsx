'use client'

import { useState } from 'react'
import { LinearVestingForm } from './LinearVestingForm'
import { TrancheVestingForm } from './TrancheVestingForm'
import { NFTSelector } from './NFTSelector'
import { TrendingUp, Calendar } from 'lucide-react'

export function CreateVestingPlan() {
  const [vestingType, setVestingType] = useState<'linear' | 'tranche'>('linear')
  const [selectedNFTs, setSelectedNFTs] = useState<number[]>([])
  const [sourceCollection, setSourceCollection] = useState('')

  return (
    <div className="space-y-8">
      <div className="text-center mb-12">
        <h2 className="text-4xl font-bold text-white mb-4">
          Create Vesting Plan
        </h2>
        <p className="text-slate-300 text-lg max-w-2xl mx-auto">
          Choose a vesting schedule for your NFTs. Create linear vesting 
          with templates or custom tranche-based schedules.
        </p>
      </div>

      {/* Vesting Type Selection */}
      <div className="bg-slate-800/50 backdrop-blur-sm border border-slate-700/50 rounded-2xl p-8">
        <h3 className="text-xl font-semibold mb-6 text-white">Select Vesting Type</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <button
            onClick={() => setVestingType('linear')}
            className={`p-8 rounded-2xl border-2 transition-all duration-200 ${
              vestingType === 'linear'
                ? 'border-purple-500 bg-gradient-to-br from-purple-500/20 to-blue-500/20 shadow-lg shadow-purple-500/25'
                : 'border-slate-600 hover:border-slate-500 bg-slate-700/30 hover:bg-slate-700/50'
            }`}
          >
            <div className="flex items-center space-x-4 mb-4">
              <div className={`p-3 rounded-xl ${
                vestingType === 'linear' 
                  ? 'bg-purple-500' 
                  : 'bg-slate-600'
              }`}>
                <TrendingUp className="h-6 w-6 text-white" />
              </div>
              <h4 className="font-semibold text-white text-lg">Linear Vesting</h4>
            </div>
            <p className="text-slate-300 text-left">
              Gradual release over time with optional cliff periods. 
              Uses pre-configured templates for common schedules.
            </p>
          </button>

          <button
            onClick={() => setVestingType('tranche')}
            className={`p-8 rounded-2xl border-2 transition-all duration-200 ${
              vestingType === 'tranche'
                ? 'border-purple-500 bg-gradient-to-br from-purple-500/20 to-blue-500/20 shadow-lg shadow-purple-500/25'
                : 'border-slate-600 hover:border-slate-500 bg-slate-700/30 hover:bg-slate-700/50'
            }`}
          >
            <div className="flex items-center space-x-4 mb-4">
              <div className={`p-3 rounded-xl ${
                vestingType === 'tranche' 
                  ? 'bg-purple-500' 
                  : 'bg-slate-600'
              }`}>
                <Calendar className="h-6 w-6 text-white" />
              </div>
              <h4 className="font-semibold text-white text-lg">Tranche Vesting</h4>
            </div>
            <p className="text-slate-300 text-left">
              Custom unlock schedule with specific dates and amounts. 
              Perfect for milestone-based releases.
            </p>
          </button>
        </div>
      </div>

      {/* NFT Selection */}
      <NFTSelector
        selectedNFTs={selectedNFTs}
        setSelectedNFTs={setSelectedNFTs}
        sourceCollection={sourceCollection}
        setSourceCollection={setSourceCollection}
      />

      {/* Vesting Form */}
      {selectedNFTs.length > 0 && sourceCollection && (
        <div className="card">
          {vestingType === 'linear' ? (
            <LinearVestingForm
              selectedNFTs={selectedNFTs}
              sourceCollection={sourceCollection}
            />
          ) : (
            <TrancheVestingForm
              selectedNFTs={selectedNFTs}
              sourceCollection={sourceCollection}
            />
          )}
        </div>
      )}
    </div>
  )
}
