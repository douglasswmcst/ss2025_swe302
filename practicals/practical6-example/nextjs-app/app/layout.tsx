import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Practical 6 - Infrastructure as Code',
  description: 'Deployed with Terraform and LocalStack',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
