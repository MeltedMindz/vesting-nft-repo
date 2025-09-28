'use client'

import { useState } from 'react'
import { useAccount, useWriteContract, useWaitForTransactionReceipt, useSwitchChain } from 'wagmi'
import { parseEther, getAddress } from 'viem'
import { useWalletClient } from 'wagmi'
import { base } from 'wagmi/chains'

// Contract ABI - you would import this from your compiled contract
const VESTING_ABI = [
  {
    "inputs": [
      {"name": "beneficiary", "type": "address"},
      {"name": "sourceCollection", "type": "address"},
      {"name": "templateId", "type": "uint256"},
      {"name": "tokenIds", "type": "uint256[]"},
      {"name": "permits", "type": "tuple[]", "components": [
        {"name": "tokenId", "type": "uint256"},
        {"name": "deadline", "type": "uint256"},
        {"name": "signature", "type": "bytes"},
        {"name": "usePermit", "type": "bool"}
      ]}
    ],
    "name": "createLinearPlan",
    "outputs": [{"name": "positionId", "type": "uint256"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"name": "beneficiary", "type": "address"},
      {"name": "sourceCollection", "type": "address"},
      {"name": "tokenIds", "type": "uint256[]"},
      {"name": "trancheSchedule", "type": "tuple[]"},
      {"name": "permits", "type": "tuple[]"}
    ],
    "name": "createTranchePlan",
    "outputs": [{"name": "positionId", "type": "uint256"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"name": "positionId", "type": "uint256"},
      {"name": "to", "type": "address"},
      {"name": "tokenIds", "type": "uint256[]"}
    ],
    "name": "claim",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"name": "positionId", "type": "uint256"}],
    "name": "getPlan",
    "outputs": [
      {
        "name": "plan",
        "type": "tuple",
        "components": [
          {"name": "sourceCollection", "type": "address"},
          {"name": "beneficiary", "type": "address"},
          {"name": "issuer", "type": "address"},
          {"name": "startTime", "type": "uint256"},
          {"name": "totalCount", "type": "uint256"},
          {"name": "claimedCount", "type": "uint256"},
          {"name": "isLinear", "type": "bool"},
          {"name": "revoked", "type": "bool"},
          {"name": "revokeTime", "type": "uint256"},
          {"name": "vestedCapOnRevoke", "type": "uint256"}
        ]
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"name": "positionId", "type": "uint256"}],
    "name": "claimableCount",
    "outputs": [{"name": "count", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  }
] as const

// ERC721 ABI for NFT approval
const ERC721_ABI = [
  {
    "inputs": [
      {"name": "to", "type": "address"},
      {"name": "tokenId", "type": "uint256"}
    ],
    "name": "approve",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"name": "operator", "type": "address"},
      {"name": "approved", "type": "bool"}
    ],
    "name": "setApprovalForAll",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"name": "owner", "type": "address"},
      {"name": "operator", "type": "address"}
    ],
    "name": "isApprovedForAll",
    "outputs": [{"name": "", "type": "bool"}],
    "stateMutability": "view",
    "type": "function"
  }
] as const

// Contract address - you would set this based on your deployment
const VESTING_CONTRACT_ADDRESS = process.env.NEXT_PUBLIC_VESTING_CONTRACT_ADDRESS || '0xe07547e2F31F5Ea2aaeD04586DB6562c17c35d5a'

// Ensure the address is properly checksummed
const getChecksumAddress = (address: string) => {
  try {
    if (!address || address === '0x0000000000000000000000000000000000000000') {
      return getAddress('0xe07547e2F31F5Ea2aaeD04586DB6562c17c35d5a')
    }
    // Clean the address by removing any whitespace/newlines
    const cleanAddress = address.trim()
    console.log('Original address:', JSON.stringify(address))
    console.log('Cleaned address:', JSON.stringify(cleanAddress))
    return getAddress(cleanAddress)
  } catch (error) {
    console.error('Error checksumming address:', address, error)
    // Return the hardcoded address if checksumming fails
    return getAddress('0xe07547e2F31F5Ea2aaeD04586DB6562c17c35d5a')
  }
}

console.log('VESTING_CONTRACT_ADDRESS:', VESTING_CONTRACT_ADDRESS)
console.log('Environment variable:', process.env.NEXT_PUBLIC_VESTING_CONTRACT_ADDRESS)

interface PermitInput {
  tokenId: number
  deadline: number
  signature: string
  usePermit: boolean
}

interface Tranche {
  timestamp: number
  count: number
}

interface CreateLinearPlanParams {
  beneficiary: string
  sourceCollection: string
  templateId: number
  tokenIds: number[]
  permits: PermitInput[]
}

interface CreateTranchePlanParams {
  beneficiary: string
  sourceCollection: string
  tokenIds: number[]
  trancheSchedule: Tranche[]
  permits: PermitInput[]
}

export function useVestingContract() {
  const { address, chain } = useAccount()
  const { data: walletClient } = useWalletClient()
  const { switchChain } = useSwitchChain()
  const [isLoading, setIsLoading] = useState(false)

  const { writeContract, data: hash, error, isPending } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  })

  const approveNFTs = async (nftContract: string, tokenIds: number[]) => {
    console.log('Approving NFTs for vesting contract...')
    console.log('NFT Contract:', nftContract)
    console.log('Vesting Contract:', VESTING_CONTRACT_ADDRESS)
    console.log('User address:', address)
    
    if (!walletClient) {
      throw new Error('Wallet client not available')
    }
    
    try {
      console.log('Calling wallet client for approval...')
      const vestingAddress = getChecksumAddress(VESTING_CONTRACT_ADDRESS)
      console.log('Approving for vesting contract:', vestingAddress)
      // First, try to set approval for all (more gas efficient for multiple NFTs)
      const hash = await walletClient.writeContract({
        address: nftContract as `0x${string}`,
        abi: ERC721_ABI,
        functionName: 'setApprovalForAll',
        args: [vestingAddress as `0x${string}`, true]
      })
      console.log('Approval transaction hash:', hash)
      return hash
    } catch (error) {
      console.error('Error setting approval for all:', error)
      throw error
    }
  }

  const createLinearPlan = async (params: CreateLinearPlanParams) => {
    if (!address) throw new Error('Wallet not connected')
    if (!walletClient) throw new Error('Wallet client not available')

    // Check if connected to Base network
    if (chain?.id !== base.id) {
      console.log('Switching to Base network...')
      try {
        await switchChain({ chainId: base.id })
        // Wait a moment for the network switch
        await new Promise(resolve => setTimeout(resolve, 1000))
      } catch (error) {
        throw new Error('Please switch to Base network to use this application')
      }
    }

    console.log('Creating linear plan with params:', params)
    console.log('Contract address:', VESTING_CONTRACT_ADDRESS)
    console.log('Current chain:', chain?.name, chain?.id)

    setIsLoading(true)
    try {
      console.log('Step 1: Approving NFTs for vesting contract...')
      // First approve the NFTs
      await approveNFTs(params.sourceCollection, params.tokenIds)
      console.log('Step 1 completed: NFTs approved')
      
      console.log('Step 2: Creating linear vesting plan...')
      console.log('Calling wallet client for createLinearPlan...')
      const checksummedAddress = getChecksumAddress(VESTING_CONTRACT_ADDRESS)
      console.log('Using checksummed address:', checksummedAddress)
      console.log('Parameters:', {
        beneficiary: params.beneficiary,
        sourceCollection: params.sourceCollection,
        templateId: params.templateId,
        tokenIds: params.tokenIds,
        permits: params.permits
      })
      // Then create the linear plan
      const hash = await walletClient.writeContract({
        address: checksummedAddress as `0x${string}`,
        abi: VESTING_ABI,
        functionName: 'createLinearPlan',
        args: [
          params.beneficiary as `0x${string}`,
          params.sourceCollection as `0x${string}`,
          BigInt(params.templateId),
          params.tokenIds?.map(id => BigInt(id)) || [],
          params.permits?.map(permit => ({
            tokenId: BigInt(permit.tokenId),
            deadline: BigInt(permit.deadline),
            signature: permit.signature as `0x${string}`,
            usePermit: permit.usePermit
          })) || []
        ]
      })
      console.log('Step 2 completed: Transaction hash:', hash)
      return hash
    } catch (error: any) {
      console.error('Error creating linear plan:', error)
      
      // Try to extract more specific error information
      if (error?.cause?.data) {
        console.error('Error data:', error.cause.data)
      }
      if (error?.shortMessage) {
        console.error('Short message:', error.shortMessage)
      }
      if (error?.message) {
        console.error('Error message:', error.message)
      }
      
      // Provide more user-friendly error message
      let userMessage = 'Error creating linear plan'
      if (error?.message?.includes('Invalid template')) {
        userMessage = 'Invalid template selected. Please try a different template.'
      } else if (error?.message?.includes('No tokens provided')) {
        userMessage = 'No NFTs selected. Please select at least one NFT.'
      } else if (error?.message?.includes('Invalid beneficiary')) {
        userMessage = 'Invalid beneficiary address.'
      } else if (error?.message?.includes('ERC721InsufficientApproval')) {
        userMessage = 'NFTs not approved. Please try again.'
      } else if (error?.message?.includes('ERC721IncorrectOwner')) {
        userMessage = 'You do not own these NFTs.'
      }
      
      throw new Error(userMessage)
    } finally {
      setIsLoading(false)
    }
  }

  const createTranchePlan = async (params: CreateTranchePlanParams) => {
    if (!address) throw new Error('Wallet not connected')

    setIsLoading(true)
    try {
      await writeContract({
        address: VESTING_CONTRACT_ADDRESS as `0x${string}`,
        abi: VESTING_ABI,
        functionName: 'createTranchePlan',
        args: [
          params.beneficiary as `0x${string}`,
          params.sourceCollection as `0x${string}`,
          params.tokenIds.map(id => BigInt(id)),
          params.trancheSchedule.map(tranche => ({
            timestamp: BigInt(tranche.timestamp),
            count: BigInt(tranche.count)
          })),
          params.permits.map(permit => ({
            tokenId: BigInt(permit.tokenId),
            deadline: BigInt(permit.deadline),
            signature: permit.signature as `0x${string}`,
            usePermit: permit.usePermit
          }))
        ]
      })
    } finally {
      setIsLoading(false)
    }
  }

  const claimTokens = async (positionId: number, to: string, tokenIds: number[]) => {
    if (!address) throw new Error('Wallet not connected')

    setIsLoading(true)
    try {
      await writeContract({
        address: VESTING_CONTRACT_ADDRESS as `0x${string}`,
        abi: VESTING_ABI,
        functionName: 'claim',
        args: [
          BigInt(positionId),
          to as `0x${string}`,
          tokenIds.map(id => BigInt(id))
        ]
      })
    } finally {
      setIsLoading(false)
    }
  }

  return {
    createLinearPlan,
    createTranchePlan,
    claimTokens,
    isLoading: isLoading || isPending || isConfirming,
    error,
    hash,
    isSuccess
  }
}
