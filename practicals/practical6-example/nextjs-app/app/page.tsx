export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24 bg-gradient-to-br from-blue-500 to-purple-600">
      <div className="text-center space-y-6">
        <h1 className="text-6xl font-bold text-white drop-shadow-lg">
          Practical 6
        </h1>
        <h2 className="text-3xl font-semibold text-white/90">
          Infrastructure as Code with Terraform
        </h2>
        <div className="bg-white/20 backdrop-blur-sm rounded-lg p-6 mt-8">
          <p className="text-xl text-white">
            🚀 Deployed via AWS CodePipeline on LocalStack
          </p>
          <p className="text-lg text-white/80 mt-4">
            Built with Next.js • Terraform • Trivy
          </p>
        </div>
        <div className="mt-8 text-white/70 text-sm">
          <p>Build Time: {new Date().toISOString()}</p>
        </div>
      </div>
    </main>
  )
}
