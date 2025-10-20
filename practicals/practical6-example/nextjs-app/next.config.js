/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  // Disable image optimization for static export
  images: {
    unoptimized: true,
  },
  // Optional: Change output directory (default is 'out')
  // distDir: 'dist',
}

module.exports = nextConfig
