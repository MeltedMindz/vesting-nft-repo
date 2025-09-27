'use client'

import { useState, useEffect } from 'react'
import { useAccount } from 'wagmi'
import { Image, Check, Plus } from 'lucide-react'

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

  // Mock NFT data - in a real app, you'd fetch from the blockchain
  const mockNFTs = [
    { id: 1, name: 'Cool NFT #1', image: '/api/placeholder/200/200' },
    { id: 2, name: 'Cool NFT #2', image: '/api/placeholder/200/200' },
    { id: 3, name: 'Cool NFT #3', image: '/api/placeholder/200/200' },
    { id: 4, name: 'Cool NFT #4', image: '/api/placeholder/200/200' },
    { id: 5, name: 'Cool NFT #5', image: '/api/placeholder/200/200' },
  ]

  useEffect(() => {
    if (sourceCollection && address) {
      setLoading(true)
      // Simulate API call
      setTimeout(() => {
        setNfts(mockNFTs)
        setLoading(false)
      }, 1000)
    }
  }, [sourceCollection, address])

  const toggleNFT = (nftId: number) => {
    if (selectedNFTs.includes(nftId)) {
      setSelectedNFTs(selectedNFTs.filter(id => id !== nftId))
    } else {
      setSelectedNFTs([...selectedNFTs, nftId])
    }
  }

  return (
    <div className="card">
      <h3 className="text-lg font-semibold mb-4">Select NFTs to Vest</h3>
      
      <div className="mb-6">
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Source Collection Address
        </label>
        <input
          type="text"
          value={sourceCollection}
          onChange={(e) => setSourceCollection(e.target.value)}
          placeholder="0x..."
          className="input"
        />
        <p className="text-sm text-gray-500 mt-1">
          Enter the contract address of the NFT collection you want to vest
        </p>
      </div>

      {sourceCollection && (
        <div>
          <div className="flex items-center justify-between mb-4">
            <h4 className="font-medium">Your NFTs</h4>
            <span className="text-sm text-gray-500">
              {selectedNFTs.length} selected
            </span>
          </div>

          {loading ? (
            <div className="flex items-center justify-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
            </div>
          ) : (
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
              {nfts.map((nft) => (
                <div
                  key={nft.id}
                  onClick={() => toggleNFT(nft.id)}
                  className={`relative cursor-pointer rounded-lg border-2 transition-all ${
                    selectedNFTs.includes(nft.id)
                      ? 'border-primary-500 bg-primary-50'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  <div className="aspect-square rounded-t-lg bg-gray-100 flex items-center justify-center">
                    <Image className="h-12 w-12 text-gray-400" />
                  </div>
                  <div className="p-3">
                    <h5 className="font-medium text-sm truncate">{nft.name}</h5>
                    <p className="text-xs text-gray-500">Token #{nft.id}</p>
                  </div>
                  {selectedNFTs.includes(nft.id) && (
                    <div className="absolute top-2 right-2 bg-primary-600 text-white rounded-full p-1">
                      <Check className="h-4 w-4" />
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}

          {selectedNFTs.length > 0 && (
            <div className="mt-4 p-4 bg-primary-50 rounded-lg">
              <div className="flex items-center space-x-2 mb-2">
                <Plus className="h-4 w-4 text-primary-600" />
                <span className="font-medium text-primary-900">
                  Selected NFTs: {selectedNFTs.length}
                </span>
              </div>
              <div className="flex flex-wrap gap-2">
                {selectedNFTs.map((id) => (
                  <span
                    key={id}
                    className="px-2 py-1 bg-primary-100 text-primary-800 text-xs rounded-full"
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
