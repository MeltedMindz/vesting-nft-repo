'use client'

import { useState, useEffect } from 'react'
import { useAccount } from 'wagmi'
import { useVestingContract } from '@/hooks/useVestingContract'
import { VestingPositionCard } from './VestingPositionCard'
import { Package, TrendingUp, Calendar, RefreshCw } from 'lucide-react'

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
  claimableCount: number
}

export function VestingDashboard() {
  const { address } = useAccount()
  const { fetchUserVestingPositions, positionBalance } = useVestingContract()
  const [positions, setPositions] = useState<VestingPosition[]>([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [filter, setFilter] = useState<'all' | 'linear' | 'tranche'>('all')

  const loadPositions = async () => {
    if (!address) {
      setPositions([])
      setLoading(false)
      return
    }

    try {
      setLoading(true)
      console.log('Loading vesting positions for user:', address)
      const userPositions = await fetchUserVestingPositions()
      console.log('Loaded positions:', userPositions)
      setPositions(userPositions)
    } catch (error) {
      console.error('Error loading vesting positions:', error)
      setPositions([])
    } finally {
      setLoading(false)
    }
  }

  const refreshPositions = async () => {
    if (!address) return
    
    try {
      setRefreshing(true)
      console.log('Refreshing vesting positions...')
      const userPositions = await fetchUserVestingPositions()
      console.log('Refreshed positions:', userPositions)
      setPositions(userPositions)
    } catch (error) {
      console.error('Error refreshing vesting positions:', error)
    } finally {
      setRefreshing(false)
    }
  }

  useEffect(() => {
    loadPositions()
  }, [address, positionBalance])

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
          <h2 className="text-2xl font-bold text-white">My Vesting Positions</h2>
          <p className="text-slate-300 mt-1">
            Manage your NFT vesting contracts and claim unlocked tokens
          </p>
          {positions.length > 0 && (
            <p className="text-sm text-slate-400 mt-1">
              {positions.length} position{positions.length !== 1 ? 's' : ''} found
            </p>
          )}
        </div>
        <div className="flex items-center space-x-3">
          <button
            onClick={refreshPositions}
            disabled={refreshing || loading}
            className="flex items-center space-x-2 px-4 py-2 bg-slate-700/50 border border-slate-600 text-slate-300 rounded-lg hover:bg-slate-600/50 hover:border-slate-500 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <RefreshCw className={`h-4 w-4 ${refreshing ? 'animate-spin' : ''}`} />
            <span className="text-sm font-medium">
              {refreshing ? 'Refreshing...' : 'Refresh'}
            </span>
          </button>
          <div className="flex space-x-2">
            <button
              onClick={() => setFilter('all')}
              className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                filter === 'all'
                  ? 'bg-purple-500 text-white'
                  : 'bg-slate-700/50 text-slate-300 hover:bg-slate-600/50'
              }`}
            >
              All
            </button>
            <button
              onClick={() => setFilter('linear')}
              className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                filter === 'linear'
                  ? 'bg-purple-500 text-white'
                  : 'bg-slate-700/50 text-slate-300 hover:bg-slate-600/50'
              }`}
            >
              <TrendingUp className="h-4 w-4 mr-1 inline" />
              Linear
            </button>
            <button
              onClick={() => setFilter('tranche')}
              className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                filter === 'tranche'
                  ? 'bg-purple-500 text-white'
                  : 'bg-slate-700/50 text-slate-300 hover:bg-slate-600/50'
              }`}
            >
              <Calendar className="h-4 w-4 mr-1 inline" />
              Tranche
            </button>
          </div>
        </div>
      </div>

      {filteredPositions.length === 0 ? (
        <div className="text-center py-12">
          <Package className="h-12 w-12 text-slate-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">
            {positions.length === 0 ? 'No vesting positions found' : 'No positions match the current filter'}
          </h3>
          <p className="text-slate-400">
            {positions.length === 0 
              ? 'Create your first vesting plan to get started'
              : 'Try changing the filter to see more positions'
            }
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
