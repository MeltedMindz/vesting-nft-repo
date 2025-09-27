import './globals.css'
import { Providers } from './providers'

export const metadata = {
  title: 'Vesting NFT Platform',
  description: 'Create and manage NFT vesting contracts',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  )
}
