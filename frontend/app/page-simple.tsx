export default function Home() {
  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow-sm border-b">
        <div className="container mx-auto px-4">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center space-x-2">
              <div className="h-8 w-8 bg-blue-600 rounded"></div>
              <h1 className="text-xl font-bold text-gray-900">Vesting NFT Platform</h1>
            </div>
            <button className="bg-blue-600 text-white px-4 py-2 rounded-lg">
              Connect Wallet
            </button>
          </div>
        </div>
      </header>
      
      <main className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="text-4xl font-bold text-gray-900 mb-6">
            NFT Vesting Platform
          </h2>
          <p className="text-xl text-gray-600 mb-8">
            Create and manage NFT vesting contracts with linear and tranche schedules
          </p>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
            <div className="bg-white p-6 rounded-lg shadow-md">
              <h3 className="text-lg font-semibold mb-3">Linear Vesting</h3>
              <p className="text-gray-600">
                Gradual release over time with configurable templates and cliff periods
              </p>
            </div>
            <div className="bg-white p-6 rounded-lg shadow-md">
              <h3 className="text-lg font-semibold mb-3">Tranche Vesting</h3>
              <p className="text-gray-600">
                Custom milestone-based unlock schedules for specific dates and amounts
              </p>
            </div>
          </div>
          
          <div className="bg-blue-50 rounded-lg p-6">
            <h3 className="text-lg font-semibold mb-2">Getting Started</h3>
            <p className="text-gray-600">
              Connect your wallet to start creating vesting plans for your NFTs
            </p>
          </div>
        </div>
      </main>
    </div>
  )
}
