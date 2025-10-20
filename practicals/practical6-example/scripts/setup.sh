#!/bin/bash
set -e

echo "🚀 Setting up Practical 6 environment..."

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

# Check if LocalStack is already running
if docker ps | grep -q practical6_localstack; then
    echo "⚠️  LocalStack is already running. Stopping it first..."
    docker-compose down
fi

# Start LocalStack
echo "Starting LocalStack..."
docker-compose up -d

# Wait for LocalStack to be ready
echo "Waiting for LocalStack to initialize (this may take 30-60 seconds)..."
sleep 10

# Test LocalStack connection
echo "Testing LocalStack connectivity..."
max_attempts=12
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if awslocal s3 ls > /dev/null 2>&1; then
        echo "✓ LocalStack is ready!"
        break
    fi
    attempt=$((attempt + 1))
    echo "Attempt $attempt/$max_attempts: Waiting for LocalStack..."
    sleep 5
done

if [ $attempt -eq $max_attempts ]; then
    echo "❌ LocalStack failed to start properly."
    echo "Check logs with: docker-compose logs localstack"
    exit 1
fi

# Display LocalStack info
echo ""
echo "✅ LocalStack is running!"
echo "   Gateway URL: http://localhost:4566"
echo "   Dashboard: https://app.localstack.cloud (if using LocalStack Pro)"
echo ""
echo "To view logs: docker-compose logs -f localstack"
echo "To stop: docker-compose down"
echo ""
