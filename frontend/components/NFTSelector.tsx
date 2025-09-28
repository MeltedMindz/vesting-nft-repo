'use client'

import { useState, useEffect } from 'react'
import { useAccount } from 'wagmi'
import { Image, Check, Plus, CheckSquare, Square, X } from 'lucide-react'

interface NFTSelectorProps {
  selectedNFTs: number[]
  setSelectedNFTs: (nfts: number[]) => void
  sourceCollection: string
  setSourceCollection: (address: string) => void
}

export function NFTSelector({
  selectedNFTs,
  setSelectedNFTs,
  sourceCollection,
  setSourceCollection,
}: NFTSelectorProps) {
  const { address } = useAccount()
  const [nfts, setNfts] = useState<any[]>([])
  const [loading, setLoading] = useState(false)

  // ERC721 ABI for fetching NFTs
  const ERC721_ABI = [
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
      "inputs": [{"name": "tokenId", "type": "uint256"}],
      "name": "tokenURI",
      "outputs": [{"name": "", "type": "string"}],
      "stateMutability": "view",
      "type": "function"
    }
  ] as const

  useEffect(() => {
    if (sourceCollection && address) {
      setLoading(true)
      fetchUserNFTs()
    }
  }, [sourceCollection, address])

  const fetchUserNFTs = async () => {
    try {
      // For now, we'll use the test NFT contract address
      const testNFTAddress = '0x8092D5f24E3da6C50F93B70dAf6A549061b127F3'
      
      // Create a simple list of NFTs 1-100 for testing
      const nftList = []
      for (let i = 1; i <= 100; i++) {
        nftList.push({
          id: i,
          name: `Test NFT #${i}`,
          image: '/api/placeholder/200/200'
        })
      }
      
      setNfts(nftList)
      setLoading(false)
    } catch (error) {
      console.error('Error fetching NFTs:', error)
      setLoading(false)
    }
  }

  const toggleNFT = (nftId: number) => {
    if (selectedNFTs.includes(nftId)) {
      setSelectedNFTs(selectedNFTs.filter(id => id !== nftId))
    } else {
      setSelectedNFTs([...selectedNFTs, nftId])
    }
  }

  const selectAllNFTs = () => {
    const allNFTIds = nfts.map(nft => nft.id)
    setSelectedNFTs(allNFTIds)
  }

  const deselectAllNFTs = () => {
    setSelectedNFTs([])
  }

  const isAllSelected = selectedNFTs.length === nfts.length && nfts.length > 0
  const isPartiallySelected = selectedNFTs.length > 0 && selectedNFTs.length < nfts.length

  const selectRange = (start: number, end: number) => {
    const rangeIds = []
    for (let i = start; i <= end && i <= nfts.length; i++) {
      rangeIds.push(i)
    }
    setSelectedNFTs([...selectedNFTs, ...rangeIds.filter(id => !selectedNFTs.includes(id))])
  }

  return (
    <div className="bg-slate-800/50 backdrop-blur-sm border border-slate-700/50 rounded-2xl p-8">
      <h3 className="text-xl font-semibold mb-6 text-white">Select NFTs to Vest</h3>
      
      <div className="mb-8">
        <label className="block text-sm font-medium text-slate-300 mb-3">
          Source Collection Address
        </label>
        <input
          type="text"
          value={sourceCollection}
          onChange={(e) => setSourceCollection(e.target.value)}
          placeholder="0x..."
          className="w-full px-4 py-3 bg-slate-700/50 border border-slate-600 rounded-xl text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
        />
        <p className="text-sm text-slate-400 mt-2">
          Enter the contract address of the NFT collection you want to vest
        </p>
      </div>

      {sourceCollection && (
        <div>
          <div className="flex items-center justify-between mb-6">
            <h4 className="font-medium text-white text-lg">Your NFTs</h4>
            <div className="flex items-center space-x-3">
              <span className="text-sm text-slate-400 bg-slate-700/50 px-3 py-1 rounded-full">
                {selectedNFTs.length} selected
              </span>
              <div className="flex items-center space-x-2">
                {selectedNFTs.length > 0 && (
                  <button
                    onClick={deselectAllNFTs}
                    className="flex items-center space-x-2 px-3 py-2 rounded-lg border border-red-500/50 text-red-400 hover:bg-red-500/10 hover:border-red-500 transition-all duration-200"
                  >
                    <X className="h-4 w-4" />
                    <span className="text-sm font-medium">Clear</span>
                  </button>
                )}
                <button
                  onClick={isAllSelected ? deselectAllNFTs : selectAllNFTs}
                  className={`flex items-center space-x-2 px-4 py-2 rounded-lg border transition-all duration-200 ${
                    isAllSelected
                      ? 'bg-purple-500/20 border-purple-500 text-purple-300 hover:bg-purple-500/30'
                      : isPartiallySelected
                      ? 'bg-yellow-500/20 border-yellow-500 text-yellow-300 hover:bg-yellow-500/30'
                      : 'bg-slate-700/50 border-slate-600 text-slate-300 hover:bg-slate-600/50 hover:border-slate-500'
                  }`}
                >
                  {isAllSelected ? (
                    <CheckSquare className="h-4 w-4" />
                  ) : isPartiallySelected ? (
                    <Square className="h-4 w-4" />
                  ) : (
                    <Square className="h-4 w-4" />
                  )}
                  <span className="text-sm font-medium">
                    {isAllSelected ? 'Deselect All' : 'Select All'}
                  </span>
                </button>
              </div>
            </div>
          </div>

          {loading ? (
            <div className="flex items-center justify-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
            </div>
          ) : (
            <>
              {/* Range Selector */}
              <div className="mb-6 p-4 bg-slate-700/30 rounded-xl border border-slate-600/50">
                <h5 className="text-sm font-medium text-slate-300 mb-3">Quick Select Ranges</h5>
                <div className="flex flex-wrap gap-2">
                  <button
                    onClick={() => selectRange(1, 10)}
                    className="px-3 py-1 text-xs bg-blue-500/20 text-blue-300 border border-blue-500/30 rounded-lg hover:bg-blue-500/30 transition-colors"
                  >
                    1-10
                  </button>
                  <button
                    onClick={() => selectRange(11, 20)}
                    className="px-3 py-1 text-xs bg-blue-500/20 text-blue-300 border border-blue-500/30 rounded-lg hover:bg-blue-500/30 transition-colors"
                  >
                    11-20
                  </button>
                  <button
                    onClick={() => selectRange(21, 30)}
                    className="px-3 py-1 text-xs bg-blue-500/20 text-blue-300 border border-blue-500/30 rounded-lg hover:bg-blue-500/30 transition-colors"
                  >
                    21-30
                  </button>
                  <button
                    onClick={() => selectRange(31, 40)}
                    className="px-3 py-1 text-xs bg-blue-500/20 text-blue-300 border border-blue-500/30 rounded-lg hover:bg-blue-500/30 transition-colors"
                  >
                    31-40
                  </button>
                  <button
                    onClick={() => selectRange(41, 50)}
                    className="px-3 py-1 text-xs bg-blue-500/20 text-blue-300 border border-blue-500/30 rounded-lg hover:bg-blue-500/30 transition-colors"
                  >
                    41-50
                  </button>
                  <button
                    onClick={() => selectRange(51, 100)}
                    className="px-3 py-1 text-xs bg-green-500/20 text-green-300 border border-green-500/30 rounded-lg hover:bg-green-500/30 transition-colors"
                  >
                    51-100
                  </button>
                </div>
              </div>
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
              {nfts.map((nft) => (
                <div
                  key={nft.id}
                  onClick={() => toggleNFT(nft.id)}
                  className={`relative cursor-pointer rounded-2xl border-2 transition-all duration-200 ${
                    selectedNFTs.includes(nft.id)
                      ? 'border-purple-500 bg-gradient-to-br from-purple-500/20 to-blue-500/20 shadow-lg shadow-purple-500/25'
                      : 'border-slate-600 hover:border-slate-500 bg-slate-700/30 hover:bg-slate-700/50'
                  }`}
                >
                  <div className="aspect-square rounded-t-2xl bg-slate-600 flex items-center justify-center">
                    <Image className="h-12 w-12 text-slate-400" />
                  </div>
                  <div className="p-4">
                    <h5 className="font-medium text-sm truncate text-white">{nft.name}</h5>
                    <p className="text-xs text-slate-400">Token #{nft.id}</p>
                  </div>
                  {selectedNFTs.includes(nft.id) && (
                    <div className="absolute top-3 right-3 bg-purple-500 text-white rounded-full p-2 shadow-lg">
                      <Check className="h-4 w-4" />
                    </div>
                  )}
                </div>
              ))}
            </div>
            </>
          )}

          {selectedNFTs.length > 0 && (
            <div className="mt-6 p-6 bg-gradient-to-r from-purple-500/10 to-blue-500/10 border border-purple-500/20 rounded-2xl">
              <div className="flex items-center space-x-3 mb-4">
                <Plus className="h-5 w-5 text-purple-400" />
                <span className="font-medium text-white text-lg">
                  Selected NFTs: {selectedNFTs.length}
                </span>
              </div>
              <div className="flex flex-wrap gap-3">
                {selectedNFTs.map((id) => (
                  <span
                    key={id}
                    className="px-3 py-2 bg-purple-500/20 text-purple-300 text-sm rounded-full border border-purple-500/30"
                  >
                    #{id}
                  </span>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
