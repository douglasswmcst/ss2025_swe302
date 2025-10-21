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
echo -e "${BLUE}Practical 6 - Deployment Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Check if LocalStack is running
echo -e "${YELLOW}[1/5] Checking LocalStack status...${NC}"
if ! curl -s http://localhost:4566/_localstack/health > /dev/null; then
    echo -e "${RED}LocalStack is not running. Starting LocalStack...${NC}"
    "$SCRIPT_DIR/setup.sh"
else
    echo -e "${GREEN}LocalStack is running${NC}"
fi
echo ""

# Step 2: Deploy infrastructure with Terraform
echo -e "${YELLOW}[2/5] Deploying infrastructure with Terraform...${NC}"
cd "$TERRAFORM_DIR"

if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    tflocal init
fi

echo "Planning Terraform changes..."
tflocal plan -out=tfplan

echo "Applying Terraform configuration..."
tflocal apply tfplan
rm -f tfplan

echo -e "${GREEN}Infrastructure deployed${NC}"
echo ""

# Step 3: Get bucket name from Terraform outputs
echo -e "${YELLOW}[3/5] Retrieving infrastructure details...${NC}"
DEPLOYMENT_BUCKET=$(terraform output -raw deployment_bucket_name)
WEBSITE_ENDPOINT=$(terraform output -raw deployment_website_endpoint)

echo -e "Deployment bucket: ${GREEN}$DEPLOYMENT_BUCKET${NC}"
echo -e "Website endpoint: ${GREEN}$WEBSITE_ENDPOINT${NC}"
echo ""

# Step 4: Build Next.js application
echo -e "${YELLOW}[4/5] Building Next.js application...${NC}"
cd "$NEXTJS_DIR"

if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm ci
fi

echo "Building Next.js app..."
npm run build

echo -e "${GREEN}Next.js build complete${NC}"
echo ""

# Step 5: Deploy to S3
echo -e "${YELLOW}[5/5] Deploying to S3...${NC}"
cd "$NEXTJS_DIR/out"

echo "Syncing files to S3 bucket..."
awslocal s3 sync . "s3://$DEPLOYMENT_BUCKET/" --delete

# Count deployed files
FILE_COUNT=$(awslocal s3 ls "s3://$DEPLOYMENT_BUCKET/" --recursive | wc -l | tr -d ' ')
echo -e "${GREEN}Deployed $FILE_COUNT files to S3${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Next steps:"
echo -e "1. Check deployment status: ${YELLOW}./scripts/status.sh${NC}"
echo -e "2. View website: ${YELLOW}$WEBSITE_ENDPOINT${NC}"
echo -e "3. List deployed files: ${YELLOW}awslocal s3 ls s3://$DEPLOYMENT_BUCKET --recursive${NC}"
echo ""
echo -e "Try it now:"
echo -e "  ${CYAN}curl $WEBSITE_ENDPOINT${NC}"
echo ""
