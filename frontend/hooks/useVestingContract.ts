'use client'

import { useState } from 'react'
import { useAccount, useWriteContract, useWaitForTransactionReceipt, useSwitchChain, useReadContract } from 'wagmi'
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
  },
  {
    "inputs": [{"name": "owner", "type": "address"}],
    "name": "balanceOf",
    "outputs": [{"name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"name": "owner", "type": "address"}, {"name": "index", "type": "uint256"}],
    "name": "tokenOfOwnerByIndex",
    "outputs": [{"name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"name": "positionId", "type": "uint256"}],
    "name": "tokenURI",
    "outputs": [{"name": "", "type": "string"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"name": "positionId", "type": "uint256"}, {"name": "timestamp", "type": "uint256"}],
    "name": "unlockedCount",
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

  // Fetch user's position NFT balance
  const { data: positionBalance } = useReadContract({
    address: getChecksumAddress(VESTING_CONTRACT_ADDRESS) as `0x${string}`,
    abi: VESTING_ABI,
    functionName: 'balanceOf',
    args: address ? [address as `0x${string}`] : undefined,
    query: {
      enabled: !!address,
    }
  })

  const approveNFTs = async (nftContract: string, tokenIds: number[]) => {
    console.log('Approving NFTs for vesting contract...')
    console.log('NFT Contract:', nftContract)
    console.log('Vesting Contract:', VESTING_CONTRACT_ADDRESS)
    console.log('User address:', address)
    
    if (!walletClient) {
      throw new Error('Wallet client not available')
    }
    
    const vestingAddress = getChecksumAddress(VESTING_CONTRACT_ADDRESS)
    console.log('Approving for vesting contract:', vestingAddress)
    
    // Retry logic for rate limiting
    let attempts = 0
    const maxAttempts = 5
    const retryDelay = 5000 // 5 seconds
    
    while (attempts < maxAttempts) {
      try {
        attempts++
        console.log(`Approval attempt ${attempts}/${maxAttempts}...`)
        
        // Try setApprovalForAll first, if it fails due to rate limiting, try individual approvals
        try {
          const hash = await walletClient.writeContract({
            address: nftContract as `0x${string}`,
            abi: ERC721_ABI,
            functionName: 'setApprovalForAll',
            args: [vestingAddress as `0x${string}`, true]
          })
          console.log('Approval transaction hash:', hash)
          return hash
        } catch (approvalError: any) {
          if (approvalError?.message?.includes('rate limited') && tokenIds.length <= 5) {
            console.log('setApprovalForAll rate limited, trying individual approvals...')
            // For small numbers of NFTs, try individual approvals
            for (const tokenId of tokenIds) {
              await walletClient.writeContract({
                address: nftContract as `0x${string}`,
                abi: ERC721_ABI,
                functionName: 'approve',
                args: [vestingAddress as `0x${string}`, BigInt(tokenId)]
              })
              // Small delay between approvals
              await new Promise(resolve => setTimeout(resolve, 1000))
            }
            console.log('Individual approvals completed')
            return '0x0000000000000000000000000000000000000000000000000000000000000000' // Dummy hash
          } else {
            throw approvalError
          }
        }
      } catch (error: any) {
        console.error(`Approval attempt ${attempts} failed:`, error)
        
        if (error?.message?.includes('rate limited') && attempts < maxAttempts) {
          console.log(`Rate limited. Waiting ${retryDelay}ms before retry...`)
          await new Promise(resolve => setTimeout(resolve, retryDelay))
          continue
        }
        
        throw error
      }
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
      
      // Retry logic for rate limiting
      let attempts = 0
      const maxAttempts = 5
      const retryDelay = 5000 // 5 seconds
      
      while (attempts < maxAttempts) {
        try {
          attempts++
          console.log(`CreateLinearPlan attempt ${attempts}/${maxAttempts}...`)
          
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
          console.error(`CreateLinearPlan attempt ${attempts} failed:`, error)
          
          if (error?.message?.includes('rate limited') && attempts < maxAttempts) {
            console.log(`Rate limited. Waiting ${retryDelay}ms before retry...`)
            await new Promise(resolve => setTimeout(resolve, retryDelay))
            continue
          }
          
          throw error
        }
      }
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
      if (error?.message?.includes('rate limited') || error?.message?.includes('Internal JSON-RPC error')) {
        userMessage = 'Network is experiencing high traffic. Please wait a few minutes and try again.'
      } else if (error?.message?.includes('Invalid template')) {
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

  const fetchUserVestingPositions = async (): Promise<VestingPosition[]> => {
    if (!address || !walletClient) {
      throw new Error('Wallet not connected')
    }

    const positions: VestingPosition[] = []
    
    try {
      // Get user's position NFT balance
      const balance = await walletClient.readContract({
        address: getChecksumAddress(VESTING_CONTRACT_ADDRESS) as `0x${string}`,
        abi: VESTING_ABI,
        functionName: 'balanceOf',
        args: [address as `0x${string}`]
      })

      console.log('User has', Number(balance), 'vesting positions')

      // Fetch each position NFT
      for (let i = 0; i < Number(balance); i++) {
        try {
          const tokenId = await walletClient.readContract({
            address: getChecksumAddress(VESTING_CONTRACT_ADDRESS) as `0x${string}`,
            abi: VESTING_ABI,
            functionName: 'tokenOfOwnerByIndex',
            args: [address as `0x${string}`, BigInt(i)]
          })

          const positionId = Number(tokenId)
          
          // Get position details
          const planData = await walletClient.readContract({
            address: getChecksumAddress(VESTING_CONTRACT_ADDRESS) as `0x${string}`,
            abi: VESTING_ABI,
            functionName: 'getPlan',
            args: [BigInt(positionId)]
          })

          // Get claimable count
          const claimableCount = await walletClient.readContract({
            address: getChecksumAddress(VESTING_CONTRACT_ADDRESS) as `0x${string}`,
            abi: VESTING_ABI,
            functionName: 'claimableCount',
            args: [BigInt(positionId)]
          })

          const position: VestingPosition = {
            id: positionId,
            sourceCollection: planData.sourceCollection,
            beneficiary: planData.beneficiary,
            issuer: planData.issuer,
            startTime: Number(planData.startTime),
            totalCount: Number(planData.totalCount),
            claimedCount: Number(planData.claimedCount),
            isLinear: planData.isLinear,
            revoked: planData.revoked,
            revokeTime: Number(planData.revokeTime),
            vestedCapOnRevoke: Number(planData.vestedCapOnRevoke),
            claimableCount: Number(claimableCount)
          }

          positions.push(position)
          console.log('Fetched position', positionId, ':', position)
        } catch (error) {
          console.error(`Error fetching position ${i}:`, error)
        }
      }
    } catch (error) {
      console.error('Error fetching vesting positions:', error)
      throw error
    }

    return positions
  }

  return {
    createLinearPlan,
    createTranchePlan,
    claimTokens,
    fetchUserVestingPositions,
    positionBalance: positionBalance ? Number(positionBalance) : 0,
    isLoading: isLoading || isPending || isConfirming,
    error,
    hash,
    isSuccess
  }
}
