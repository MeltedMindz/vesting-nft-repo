'use client'

import { useState } from 'react'
import { useAccount } from 'wagmi'
import { useVestingContract } from '@/hooks/useVestingContract'
import { Clock, Calendar, TrendingUp } from 'lucide-react'

interface LinearVestingFormProps {
  selectedNFTs: number[]
  sourceCollection: string
}

export function LinearVestingForm({ selectedNFTs, sourceCollection }: LinearVestingFormProps) {
  const { address } = useAccount()
  const { createLinearPlan, isLoading } = useVestingContract()
  const [beneficiary, setBeneficiary] = useState('')
  const [templateId, setTemplateId] = useState(1)
  const [isCreating, setIsCreating] = useState(false)

  // Templates configured in the contract
  const templates = [
    { id: 1, name: '3 Month Cliff, 12 Month Duration', cliff: 90 * 24 * 60 * 60, duration: 365 * 24 * 60 * 60, slice: 24 * 60 * 60 },
    { id: 2, name: '6 Month Duration, Weekly Release', cliff: 0, duration: 180 * 24 * 60 * 60, slice: 7 * 24 * 60 * 60 },
    { id: 3, name: '1 Month Cliff, 24 Month Duration', cliff: 30 * 24 * 60 * 60, duration: 2 * 365 * 24 * 60 * 60, slice: 24 * 60 * 60 },
    { id: 4, name: '1 Year Continuous', cliff: 0, duration: 365 * 24 * 60 * 60, slice: 0 },
  ]

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!address || !beneficiary) return

    console.log('Submitting linear vesting form...')
    console.log('Beneficiary:', beneficiary)
    console.log('Source Collection:', sourceCollection)
    console.log('Template ID:', templateId)
    console.log('Selected NFTs:', selectedNFTs)

    setIsCreating(true)
    try {
      console.log('Starting linear plan creation process...')
      console.log('Step 1: Approving NFTs for vesting contract...')
      
      const result = await createLinearPlan({
        beneficiary,
        sourceCollection,
        templateId,
        tokenIds: selectedNFTs,
        permits: selectedNFTs.map(id => ({
          tokenId: id,
          deadline: 0,
          signature: '',
          usePermit: false
        }))
      })
      console.log('Linear plan creation result:', result)
      alert('Linear vesting plan created successfully! Check your wallet for the position NFT.')
    } catch (error) {
      console.error('Error creating linear plan:', error)
      const errorMessage = error instanceof Error ? error.message : String(error)
      alert(`Error creating linear plan: ${errorMessage}`)
    } finally {
      setIsCreating(false)
    }
  }

  const selectedTemplate = templates.find(t => t.id === templateId)

  return (
    <div>
      <h3 className="text-lg font-semibold mb-6">Linear Vesting Configuration</h3>
      
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
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Vesting Template
          </label>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            {templates.map((template) => (
              <button
                key={template.id}
                type="button"
                onClick={() => setTemplateId(template.id)}
                className={`p-4 rounded-lg border-2 text-left transition-all ${
                  templateId === template.id
                    ? 'border-primary-500 bg-primary-50'
                    : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                <div className="flex items-center space-x-3 mb-2">
                  <TrendingUp className="h-5 w-5 text-primary-600" />
                  <h4 className="font-medium">{template.name}</h4>
                </div>
                <div className="text-sm text-gray-600 space-y-1">
                  {template.cliff > 0 && (
                    <div className="flex items-center space-x-2">
                      <Clock className="h-4 w-4" />
                      <span>Cliff: {Math.floor(template.cliff / (24 * 60 * 60))} days</span>
                    </div>
                  )}
                  <div className="flex items-center space-x-2">
                    <Calendar className="h-4 w-4" />
                    <span>Duration: {Math.floor(template.duration / (365 * 24 * 60 * 60))} years</span>
                  </div>
                  {template.slice > 0 && (
                    <div className="text-xs text-gray-500">
                      Slice: {Math.floor(template.slice / (24 * 60 * 60))} days
                    </div>
                  )}
                </div>
              </button>
            ))}
          </div>
        </div>

        {selectedTemplate && (
          <div className="bg-gray-50 rounded-lg p-4">
            <h4 className="font-medium mb-2">Template Details</h4>
            <div className="text-sm text-gray-600 space-y-1">
              <div>Cliff Period: {selectedTemplate.cliff === 0 ? 'None' : `${Math.floor(selectedTemplate.cliff / (24 * 60 * 60))} days`}</div>
              <div>Total Duration: {Math.floor(selectedTemplate.duration / (365 * 24 * 60 * 60))} years</div>
              <div>Slice Period: {selectedTemplate.slice === 0 ? 'Continuous' : `${Math.floor(selectedTemplate.slice / (24 * 60 * 60))} days`}</div>
            </div>
          </div>
        )}

        <div className="flex items-center justify-between pt-4 border-t">
          <div className="text-sm text-gray-600">
            Vesting {selectedNFTs.length} NFTs to {beneficiary || 'beneficiary'}
          </div>
          <button
            type="submit"
            disabled={!beneficiary || isCreating || isLoading}
            className="btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isCreating ? 'Creating...' : 'Create Linear Plan'}
          </button>
        </div>
      </form>
    </div>
  )
}
