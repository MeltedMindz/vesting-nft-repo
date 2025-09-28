'use client'

import { ConnectButton } from '@rainbow-me/rainbowkit'
import { Lock, Menu, X, AlertTriangle } from 'lucide-react'
import { useState } from 'react'
import { useAccount } from 'wagmi'
import { base } from 'wagmi/chains'

export function Header() {
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const { chain, isConnected } = useAccount()
  
  const isWrongNetwork = isConnected && chain?.id !== base.id

  return (
    <>
      {isWrongNetwork && (
        <div className="bg-red-600 text-white text-center py-2 text-sm">
          <div className="flex items-center justify-center space-x-2">
            <AlertTriangle className="h-4 w-4" />
            <span>Please switch to Base network to use this application</span>
          </div>
        </div>
      )}
      <header className="bg-slate-900/50 backdrop-blur-md border-b border-slate-700/50 sticky top-0 z-50">
        <div className="container mx-auto px-4">
          <div className="flex items-center justify-between h-16">
          <div className="flex items-center space-x-3">
            <div className="flex items-center justify-center w-10 h-10 bg-gradient-to-br from-purple-500 to-blue-500 rounded-xl">
              <Lock className="h-6 w-6 text-white" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-white">Vesting NFT</h1>
              <p className="text-xs text-slate-400">Position Management</p>
            </div>
          </div>
          
          <div className="hidden md:flex items-center space-x-6">
            <nav className="flex items-center space-x-6">
              <a href="#" className="text-slate-300 hover:text-white transition-colors">Dashboard</a>
              <a href="#" className="text-slate-300 hover:text-white transition-colors">Create</a>
              <a href="#" className="text-slate-300 hover:text-white transition-colors">Docs</a>
            </nav>
            <ConnectButton />
          </div>

          <div className="md:hidden">
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="text-slate-300 hover:text-white"
            >
              {isMenuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
            </button>
          </div>
        </div>

        {isMenuOpen && (
          <div className="md:hidden py-4 border-t border-slate-700/50">
            <nav className="flex flex-col space-y-4">
              <a href="#" className="text-slate-300 hover:text-white transition-colors">Dashboard</a>
              <a href="#" className="text-slate-300 hover:text-white transition-colors">Create</a>
              <a href="#" className="text-slate-300 hover:text-white transition-colors">Docs</a>
              <div className="pt-4">
                <ConnectButton />
              </div>
            </nav>
          </div>
        )}
      </div>
    </header>
    </>
  )
}
