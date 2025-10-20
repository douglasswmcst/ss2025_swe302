#!/bin/bash
echo "LocalStack initialization starting..."

# Wait for LocalStack to be ready
sleep 2

# Verify services are available
awslocal s3 ls > /dev/null 2>&1 && echo "✓ S3 service ready" || echo "✗ S3 service not ready"
awslocal iam list-roles > /dev/null 2>&1 && echo "✓ IAM service ready" || echo "✗ IAM service not ready"

echo "LocalStack initialization complete!"
