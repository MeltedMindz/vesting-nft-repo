'use client'

import { useState, useEffect } from 'react'
import { useAccount } from 'wagmi'
import { useVestingContract } from '@/hooks/useVestingContract'
import { VestingPositionCard } from './VestingPositionCard'
import { Package, TrendingUp, Calendar } from 'lucide-react'

interface VestingPosition {
  id: number
  sourceCollection: string
  beneficiary: string
  issuer: string
  startTime: number
  totalCount: number
  claimedCount: number
  isLinear: boolean
  revoked: boolean
  revokeTime: number
  vestedCapOnRevoke: number
}

export function VestingDashboard() {
  const { address } = useAccount()
  const [positions, setPositions] = useState<VestingPosition[]>([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState<'all' | 'linear' | 'tranche'>('all')

  // Mock data - in a real app, you'd fetch from the blockchain
  const mockPositions: VestingPosition[] = [
    {
      id: 1,
      sourceCollection: '0x1234...5678',
      beneficiary: '0xabcd...efgh',
      issuer: address || '0x...',
      startTime: Math.floor(Date.now() / 1000) - 30 * 24 * 60 * 60,
      totalCount: 5,
      claimedCount: 2,
      isLinear: true,
      revoked: false,
      revokeTime: 0,
      vestedCapOnRevoke: 0
    },
    {
      id: 2,
      sourceCollection: '0x9876...5432',
      beneficiary: '0xijkl...mnop',
      issuer: address || '0x...',
      startTime: Math.floor(Date.now() / 1000) - 15 * 24 * 60 * 60,
      totalCount: 3,
      claimedCount: 0,
      isLinear: false,
      revoked: false,
      revokeTime: 0,
      vestedCapOnRevoke: 0
    }
  ]

  useEffect(() => {
    if (address) {
      setLoading(true)
      // Simulate API call
      setTimeout(() => {
        setPositions(mockPositions)
        setLoading(false)
      }, 1000)
    }
  }, [address])

  const filteredPositions = positions.filter(position => {
    if (filter === 'all') return true
    if (filter === 'linear') return position.isLinear
    if (filter === 'tranche') return !position.isLinear
    return true
  })

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">My Vesting Positions</h2>
          <p className="text-gray-600 mt-1">
            Manage your NFT vesting contracts and claim unlocked tokens
          </p>
        </div>
        <div className="flex space-x-2">
          <button
            onClick={() => setFilter('all')}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${
              filter === 'all'
                ? 'bg-primary-600 text-white'
                : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
            }`}
          >
            All
          </button>
          <button
            onClick={() => setFilter('linear')}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${
              filter === 'linear'
                ? 'bg-primary-600 text-white'
                : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
            }`}
          >
            <TrendingUp className="h-4 w-4 mr-1 inline" />
            Linear
          </button>
          <button
            onClick={() => setFilter('tranche')}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${
              filter === 'tranche'
                ? 'bg-primary-600 text-white'
                : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
            }`}
          >
            <Calendar className="h-4 w-4 mr-1 inline" />
            Tranche
          </button>
        </div>
      </div>

      {filteredPositions.length === 0 ? (
        <div className="text-center py-12">
          <Package className="h-12 w-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">
            No vesting positions found
          </h3>
          <p className="text-gray-600">
            Create your first vesting plan to get started
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {filteredPositions.map((position) => (
            <VestingPositionCard key={position.id} position={position} />
          ))}
        </div>
      )}
    </div>
  )
}
