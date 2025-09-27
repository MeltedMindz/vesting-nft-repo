#!/bin/bash

# Vesting NFT Frontend Deployment Script
# This script helps deploy the frontend to Vercel

echo "🚀 Deploying Vesting NFT Frontend..."

# Check if .env.local exists
if [ ! -f .env.local ]; then
    echo "❌ .env.local file not found!"
    echo "Please copy env.example to .env.local and configure your environment variables:"
    echo "cp env.example .env.local"
    exit 1
fi

# Check if required environment variables are set
if ! grep -q "NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID" .env.local || ! grep -q "NEXT_PUBLIC_VESTING_CONTRACT_ADDRESS" .env.local; then
    echo "❌ Required environment variables not set!"
    echo "Please set the following in your .env.local file:"
    echo "- NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID"
    echo "- NEXT_PUBLIC_VESTING_CONTRACT_ADDRESS"
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Build the project
echo "🔨 Building project..."
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "🎉 Your frontend is ready for deployment!"
    echo ""
    echo "Next steps:"
    echo "1. Deploy to Vercel: npx vercel --prod"
    echo "2. Or deploy to Netlify: npm run build && netlify deploy --prod --dir=out"
    echo "3. Or deploy to any static hosting service"
    echo ""
    echo "Don't forget to set your environment variables in your hosting platform!"
else
    echo "❌ Build failed!"
    exit 1
fi
