'use client'

import { useState } from 'react'
import { useAccount } from 'wagmi'
import { useVestingContract } from '@/hooks/useVestingContract'
import { Calendar, Plus, Trash2 } from 'lucide-react'
import { format, addDays } from 'date-fns'

interface TrancheVestingFormProps {
  selectedNFTs: number[]
  sourceCollection: string
}

interface Tranche {
  timestamp: number
  count: number
}

export function TrancheVestingForm({ selectedNFTs, sourceCollection }: TrancheVestingFormProps) {
  const { address } = useAccount()
  const { createTranchePlan, isLoading } = useVestingContract()
  const [beneficiary, setBeneficiary] = useState('')
  const [tranches, setTranches] = useState<Tranche[]>([
    { timestamp: Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60, count: 1 },
    { timestamp: Math.floor(Date.now() / 1000) + 60 * 24 * 60 * 60, count: 2 },
  ])
  const [isCreating, setIsCreating] = useState(false)

  const addTranche = () => {
    const lastTranche = tranches[tranches.length - 1]
    setTranches([
      ...tranches,
      {
        timestamp: lastTranche.timestamp + 30 * 24 * 60 * 60,
        count: Math.min(lastTranche.count + 1, selectedNFTs.length)
      }
    ])
  }

  const removeTranche = (index: number) => {
    if (tranches.length > 1) {
      setTranches(tranches.filter((_, i) => i !== index))
    }
  }

  const updateTranche = (index: number, field: keyof Tranche, value: number) => {
    const newTranches = [...tranches]
    newTranches[index] = { ...newTranches[index], [field]: value }
    setTranches(newTranches)
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!address || !beneficiary) return

    setIsCreating(true)
    try {
      await createTranchePlan({
        beneficiary,
        sourceCollection,
        tokenIds: selectedNFTs,
        trancheSchedule: tranches,
        permits: selectedNFTs.map(id => ({
          tokenId: id,
          deadline: 0,
          signature: '',
          usePermit: false
        }))
      })
    } catch (error) {
      console.error('Error creating tranche plan:', error)
    } finally {
      setIsCreating(false)
    }
  }

  return (
    <div>
      <h3 className="text-lg font-semibold mb-6">Tranche Vesting Configuration</h3>
      
      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Beneficiary Address
          </label>
          <input
            type="text"
            value={beneficiary}
            onChange={(e) => setBeneficiary(e.target.value)}
            placeholder="0x..."
            className="input"
            required
          />
          <p className="text-sm text-gray-500 mt-1">
            Who will receive the vested NFTs
          </p>
        </div>

        <div>
          <div className="flex items-center justify-between mb-4">
            <label className="block text-sm font-medium text-gray-700">
              Tranche Schedule
            </label>
            <button
              type="button"
              onClick={addTranche}
              className="btn-secondary text-sm"
            >
              <Plus className="h-4 w-4 mr-1" />
              Add Tranche
            </button>
          </div>

          <div className="space-y-3">
            {tranches.map((tranche, index) => (
              <div key={index} className="flex items-center space-x-4 p-4 border rounded-lg">
                <div className="flex-1">
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Unlock Date
                  </label>
                  <input
                    type="datetime-local"
                    value={format(new Date(tranche.timestamp * 1000), "yyyy-MM-dd'T'HH:mm")}
                    onChange={(e) => updateTranche(index, 'timestamp', Math.floor(new Date(e.target.value).getTime() / 1000))}
                    className="input"
                  />
                </div>
                <div className="flex-1">
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Cumulative Count
                  </label>
                  <input
                    type="number"
                    min="1"
                    max={selectedNFTs.length}
                    value={tranche.count}
                    onChange={(e) => updateTranche(index, 'count', parseInt(e.target.value))}
                    className="input"
                  />
                </div>
                <div className="flex items-end">
                  {tranches.length > 1 && (
                    <button
                      type="button"
                      onClick={() => removeTranche(index)}
                      className="p-2 text-red-600 hover:bg-red-50 rounded"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>

          <div className="mt-4 p-4 bg-blue-50 rounded-lg">
            <h4 className="font-medium text-blue-900 mb-2">Schedule Preview</h4>
            <div className="text-sm text-blue-800 space-y-1">
              {tranches.map((tranche, index) => (
                <div key={index} className="flex items-center space-x-2">
                  <Calendar className="h-4 w-4" />
                  <span>
                    {format(new Date(tranche.timestamp * 1000), 'MMM dd, yyyy')} - 
                    {index === 0 ? tranche.count : tranche.count - tranches[index - 1].count} NFTs unlock
                    (Total: {tranche.count})
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="flex items-center justify-between pt-4 border-t">
          <div className="text-sm text-gray-600">
            Vesting {selectedNFTs.length} NFTs to {beneficiary || 'beneficiary'}
          </div>
          <button
            type="submit"
            disabled={!beneficiary || isCreating || isLoading}
            className="btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isCreating ? 'Creating...' : 'Create Tranche Plan'}
          </button>
        </div>
      </form>
    </div>
  )
}
