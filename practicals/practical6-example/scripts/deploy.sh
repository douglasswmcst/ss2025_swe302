#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
NEXTJS_DIR="$PROJECT_ROOT/nextjs-app"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Practical 6 - Full Deployment Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Check if LocalStack is running
echo -e "${YELLOW}[1/7] Checking LocalStack status...${NC}"
if ! curl -s http://localhost:4566/_localstack/health > /dev/null; then
    echo -e "${RED}LocalStack is not running. Starting LocalStack...${NC}"
    "$SCRIPT_DIR/setup.sh"
else
    echo -e "${GREEN}LocalStack is running${NC}"
fi
echo ""

# Step 2: Build Next.js application
echo -e "${YELLOW}[2/7] Building Next.js application...${NC}"
cd "$NEXTJS_DIR"
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm ci
fi
echo "Building Next.js app..."
npm run build
echo -e "${GREEN}Next.js build complete${NC}"
echo ""

# Step 3: Package application
echo -e "${YELLOW}[3/7] Packaging application as ZIP...${NC}"
cd "$NEXTJS_DIR/out"
zip -r "$PROJECT_ROOT/nextjs-app.zip" . > /dev/null
echo -e "${GREEN}Created nextjs-app.zip ($(du -h "$PROJECT_ROOT/nextjs-app.zip" | cut -f1))${NC}"
echo ""

# Step 4: Initialize and apply Terraform
echo -e "${YELLOW}[4/7] Deploying infrastructure with Terraform...${NC}"
cd "$TERRAFORM_DIR"

if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
fi

echo "Planning Terraform changes..."
terraform plan -out=tfplan

echo "Applying Terraform configuration..."
terraform apply tfplan
rm -f tfplan

echo -e "${GREEN}Infrastructure deployed${NC}"
echo ""

# Step 5: Get bucket names from Terraform outputs
echo -e "${YELLOW}[5/7] Retrieving infrastructure details...${NC}"
SOURCE_BUCKET=$(terraform output -raw source_bucket_name)
PIPELINE_NAME=$(terraform output -raw pipeline_name)
WEBSITE_ENDPOINT=$(terraform output -raw deployment_website_endpoint)

echo -e "Source bucket: ${GREEN}$SOURCE_BUCKET${NC}"
echo -e "Pipeline: ${GREEN}$PIPELINE_NAME${NC}"
echo -e "Website endpoint: ${GREEN}$WEBSITE_ENDPOINT${NC}"
echo ""

# Step 6: Upload source code to S3
echo -e "${YELLOW}[6/7] Uploading source code to S3...${NC}"
awslocal s3 cp "$PROJECT_ROOT/nextjs-app.zip" "s3://$SOURCE_BUCKET/nextjs-app.zip"
echo -e "${GREEN}Source code uploaded${NC}"
echo ""

# Step 7: Trigger pipeline execution
echo -e "${YELLOW}[7/7] Triggering CodePipeline execution...${NC}"
EXECUTION_ID=$(awslocal codepipeline start-pipeline-execution \
    --name "$PIPELINE_NAME" \
    --query 'pipelineExecutionId' \
    --output text)
echo -e "${GREEN}Pipeline execution started: $EXECUTION_ID${NC}"
echo ""

# Monitor pipeline status
echo -e "${BLUE}Monitoring pipeline execution...${NC}"
echo "Use './scripts/status.sh' to check pipeline status"
echo ""

# Wait a moment and show initial status
sleep 5
PIPELINE_STATE=$(awslocal codepipeline get-pipeline-state --name "$PIPELINE_NAME" 2>/dev/null || echo "")

if [ -n "$PIPELINE_STATE" ]; then
    echo -e "${BLUE}Current pipeline stages:${NC}"
    echo "$PIPELINE_STATE" | grep -E "stageName|actionName|status" | head -20 || echo "Status not yet available"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Next steps:"
echo -e "1. Check pipeline status: ${YELLOW}./scripts/status.sh${NC}"
echo -e "2. View website: ${YELLOW}$WEBSITE_ENDPOINT${NC}"
echo -e "3. View logs: ${YELLOW}awslocal logs tail /aws/codebuild/$PIPELINE_NAME-build --follow${NC}"
echo ""
