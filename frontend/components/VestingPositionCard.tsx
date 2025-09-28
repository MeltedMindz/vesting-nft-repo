'use client'

import { useState } from 'react'
import { useAccount } from 'wagmi'
import { useVestingContract } from '@/hooks/useVestingContract'
import { format } from 'date-fns'
import { 
  TrendingUp, 
  Calendar, 
  Clock, 
  CheckCircle, 
  XCircle, 
  Download,
  ExternalLink
} from 'lucide-react'

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

interface VestingPositionCardProps {
  position: VestingPosition
}

export function VestingPositionCard({ position }: VestingPositionCardProps) {
  const { address } = useAccount()
  const { claimTokens, isLoading } = useVestingContract()
  const [isClaiming, setIsClaiming] = useState(false)

  const isOwner = position.beneficiary.toLowerCase() === address?.toLowerCase()
  const isIssuer = position.issuer.toLowerCase() === address?.toLowerCase()
  const canClaim = isOwner && !position.revoked
  const claimableCount = Math.max(0, position.totalCount - position.claimedCount)

  const handleClaim = async () => {
    if (!address || !canClaim) return

    setIsClaiming(true)
    try {
      // In a real app, you'd get the actual claimable token IDs
      const claimableTokenIds = Array.from({ length: claimableCount }, (_, i) => i + 1)
      await claimTokens(position.id, address, claimableTokenIds)
    } catch (error) {
      console.error('Error claiming tokens:', error)
    } finally {
      setIsClaiming(false)
    }
  }

  const getStatusColor = () => {
    if (position.revoked) return 'text-red-600 bg-red-100'
    if (position.claimedCount === position.totalCount) return 'text-green-600 bg-green-100'
    return 'text-blue-600 bg-blue-100'
  }

  const getStatusText = () => {
    if (position.revoked) return 'Revoked'
    if (position.claimedCount === position.totalCount) return 'Completed'
    return 'Active'
  }

  return (
    <div className="card">
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center space-x-3">
          {position.isLinear ? (
            <TrendingUp className="h-6 w-6 text-primary-600" />
          ) : (
            <Calendar className="h-6 w-6 text-primary-600" />
          )}
          <div>
            <h3 className="font-semibold text-gray-900">
              Position #{position.id}
            </h3>
            <p className="text-sm text-gray-600">
              {position.isLinear ? 'Linear Vesting' : 'Tranche Vesting'}
            </p>
          </div>
        </div>
        <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor()}`}>
          {getStatusText()}
        </span>
      </div>

      <div className="space-y-3 mb-4">
        <div className="flex justify-between text-sm">
          <span className="text-gray-600">Source Collection:</span>
          <span className="font-mono text-xs bg-gray-100 px-2 py-1 rounded">
            {position.sourceCollection.slice(0, 6)}...{position.sourceCollection.slice(-4)}
          </span>
        </div>
        
        <div className="flex justify-between text-sm">
          <span className="text-gray-600">Beneficiary:</span>
          <span className="font-mono text-xs bg-gray-100 px-2 py-1 rounded">
            {position.beneficiary.slice(0, 6)}...{position.beneficiary.slice(-4)}
          </span>
        </div>

        <div className="flex justify-between text-sm">
          <span className="text-gray-600">Start Date:</span>
          <span>{format(new Date(position.startTime * 1000), 'MMM dd, yyyy')}</span>
        </div>

        <div className="flex justify-between text-sm">
          <span className="text-gray-600">Total NFTs:</span>
          <span className="font-medium">{position.totalCount}</span>
        </div>

        <div className="flex justify-between text-sm">
          <span className="text-gray-600">Claimed:</span>
          <span className="font-medium">{position.claimedCount}</span>
        </div>

        <div className="flex justify-between text-sm">
          <span className="text-gray-600">Remaining:</span>
          <span className="font-medium">{claimableCount}</span>
        </div>
      </div>

      {/* Progress Bar */}
      <div className="mb-4">
        <div className="flex justify-between text-sm mb-1">
          <span>Progress</span>
          <span>{Math.round((position.claimedCount / position.totalCount) * 100)}%</span>
        </div>
        <div className="w-full bg-gray-200 rounded-full h-2">
          <div 
            className="bg-primary-600 h-2 rounded-full transition-all duration-300"
            style={{ width: `${(position.claimedCount / position.totalCount) * 100}%` }}
          />
        </div>
      </div>

      {/* Actions */}
      <div className="flex space-x-2">
        {canClaim && claimableCount > 0 && (
          <button
            onClick={handleClaim}
            disabled={isClaiming || isLoading}
            className="flex-1 btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isClaiming ? (
              <div className="flex items-center justify-center">
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                Claiming...
              </div>
            ) : (
              <div className="flex items-center justify-center">
                <Download className="h-4 w-4 mr-2" />
                Claim {claimableCount} NFTs
              </div>
            )}
          </button>
        )}

        <button className="btn-secondary">
          <ExternalLink className="h-4 w-4 mr-1" />
          View
        </button>
      </div>

      {/* Additional Info */}
      {position.revoked && (
        <div className="mt-4 p-3 bg-red-50 rounded-lg">
          <div className="flex items-center space-x-2 text-red-800">
            <XCircle className="h-4 w-4" />
            <span className="text-sm font-medium">Plan Revoked</span>
          </div>
          <p className="text-xs text-red-600 mt-1">
            This vesting plan was revoked on {format(new Date(position.revokeTime * 1000), 'MMM dd, yyyy')}
          </p>
        </div>
      )}

      {!position.revoked && position.claimedCount === position.totalCount && (
        <div className="mt-4 p-3 bg-green-50 rounded-lg">
          <div className="flex items-center space-x-2 text-green-800">
            <CheckCircle className="h-4 w-4" />
            <span className="text-sm font-medium">Fully Claimed</span>
          </div>
          <p className="text-xs text-green-600 mt-1">
            All tokens have been successfully claimed
          </p>
        </div>
      )}
    </div>
  )
}
