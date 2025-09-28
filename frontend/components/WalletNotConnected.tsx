'use client'

import { Wallet, ArrowRight, Shield, Zap } from 'lucide-react'

export function WalletNotConnected() {
  return (
    <div className="flex items-center justify-center min-h-[70vh] px-4">
      <div className="text-center max-w-2xl mx-auto">
        <div className="relative mb-8">
          <div className="absolute inset-0 bg-gradient-to-r from-purple-500/20 to-blue-500/20 rounded-3xl blur-3xl transform rotate-3"></div>
          <div className="relative bg-slate-800/50 backdrop-blur-sm border border-slate-700/50 rounded-3xl p-8">
            <div className="flex items-center justify-center w-20 h-20 bg-gradient-to-br from-purple-500 to-blue-500 rounded-2xl mx-auto mb-6">
              <Wallet className="h-10 w-10 text-white" />
            </div>
            <h2 className="text-3xl font-bold text-white mb-4">
              Connect Your Wallet
            </h2>
            <p className="text-slate-300 text-lg mb-8 leading-relaxed">
              Connect your wallet to create and manage NFT vesting contracts. 
              Create linear or tranche-based vesting plans for your NFTs with our secure platform.
            </p>
            <div className="flex items-center justify-center text-slate-400 mb-8">
              <ArrowRight className="h-5 w-5 mr-2" />
              Click the "Connect Wallet" button above to get started
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mt-12">
          <div className="bg-slate-800/30 backdrop-blur-sm border border-slate-700/30 rounded-2xl p-6">
            <div className="flex items-center justify-center w-12 h-12 bg-gradient-to-br from-green-500 to-emerald-500 rounded-xl mb-4 mx-auto">
              <Shield className="h-6 w-6 text-white" />
            </div>
            <h3 className="text-lg font-semibold text-white mb-2">Secure Vesting</h3>
            <p className="text-slate-400 text-sm">
              Your NFTs are safely escrowed with smart contract security
            </p>
          </div>
          <div className="bg-slate-800/30 backdrop-blur-sm border border-slate-700/30 rounded-2xl p-6">
            <div className="flex items-center justify-center w-12 h-12 bg-gradient-to-br from-yellow-500 to-orange-500 rounded-xl mb-4 mx-auto">
              <Zap className="h-6 w-6 text-white" />
            </div>
            <h3 className="text-lg font-semibold text-white mb-2">Flexible Schedules</h3>
            <p className="text-slate-400 text-sm">
              Create linear or custom tranche-based unlock schedules
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
