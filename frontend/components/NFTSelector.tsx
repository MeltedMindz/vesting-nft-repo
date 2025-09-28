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
            <span className="text-sm text-slate-400 bg-slate-700/50 px-3 py-1 rounded-full">
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
