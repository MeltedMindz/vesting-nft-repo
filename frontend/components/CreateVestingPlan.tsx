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
      <div className="text-center">
        <h2 className="text-3xl font-bold text-gray-900 mb-4">
          Create Vesting Plan
        </h2>
        <p className="text-gray-600 max-w-2xl mx-auto">
          Choose a vesting schedule for your NFTs. You can create linear vesting 
          with templates or custom tranche-based schedules.
        </p>
      </div>

      {/* Vesting Type Selection */}
      <div className="card">
        <h3 className="text-lg font-semibold mb-4">Select Vesting Type</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <button
            onClick={() => setVestingType('linear')}
            className={`p-6 rounded-lg border-2 transition-all ${
              vestingType === 'linear'
                ? 'border-primary-500 bg-primary-50'
                : 'border-gray-200 hover:border-gray-300'
            }`}
          >
            <div className="flex items-center space-x-3 mb-3">
              <TrendingUp className="h-6 w-6 text-primary-600" />
              <h4 className="font-semibold">Linear Vesting</h4>
            </div>
            <p className="text-sm text-gray-600">
              Gradual release over time with optional cliff periods. 
              Uses pre-configured templates for common schedules.
            </p>
          </button>

          <button
            onClick={() => setVestingType('tranche')}
            className={`p-6 rounded-lg border-2 transition-all ${
              vestingType === 'tranche'
                ? 'border-primary-500 bg-primary-50'
                : 'border-gray-200 hover:border-gray-300'
            }`}
          >
            <div className="flex items-center space-x-3 mb-3">
              <Calendar className="h-6 w-6 text-primary-600" />
              <h4 className="font-semibold">Tranche Vesting</h4>
            </div>
            <p className="text-sm text-gray-600">
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
