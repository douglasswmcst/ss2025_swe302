#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
GITHUB_REPO="${GITHUB_REPO:-YOUR_USERNAME/practical6-nextjs-app}"
CLONE_DIR="${CLONE_DIR:-/tmp/practical6-deploy}"
BRANCH="${BRANCH:-main}"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}GitHub-based Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Repository: ${CYAN}https://github.com/$GITHUB_REPO${NC}"
echo -e "Branch: ${CYAN}$BRANCH${NC}"
echo -e "Clone directory: ${CYAN}$CLONE_DIR${NC}"
echo ""

# Step 1: Check LocalStack
echo -e "${YELLOW}[1/6] Checking LocalStack status...${NC}"
if ! curl -s http://localhost:4566/_localstack/health > /dev/null; then
    echo -e "${RED}LocalStack is not running. Starting LocalStack...${NC}"
    "$SCRIPT_DIR/setup.sh"
else
    echo -e "${GREEN}LocalStack is running${NC}"
fi
echo ""

# Step 2: Check infrastructure
echo -e "${YELLOW}[2/6] Checking infrastructure...${NC}"
cd "$TERRAFORM_DIR"
if [ ! -f "terraform.tfstate" ]; then
    echo -e "${YELLOW}Infrastructure not deployed. Deploying now...${NC}"
    tflocal init
    tflocal apply -auto-approve
else
    echo -e "${GREEN}Infrastructure already deployed${NC}"
fi

DEPLOYMENT_BUCKET=$(terraform output -raw deployment_bucket_name)
WEBSITE_ENDPOINT=$(terraform output -raw deployment_website_endpoint)
echo -e "Deployment bucket: ${GREEN}$DEPLOYMENT_BUCKET${NC}"
echo ""

# Step 3: Clone/update repository
echo -e "${YELLOW}[3/6] Fetching latest code from GitHub...${NC}"
if [ -d "$CLONE_DIR" ]; then
    echo "Updating existing repository..."
    cd "$CLONE_DIR"
    git fetch origin
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
else
    echo "Cloning repository..."
    git clone "https://github.com/$GITHUB_REPO.git" "$CLONE_DIR"
    cd "$CLONE_DIR"
    git checkout "$BRANCH"
fi

COMMIT_HASH=$(git rev-parse --short HEAD)
COMMIT_MSG=$(git log -1 --pretty=%B)
AUTHOR=$(git log -1 --pretty=%an)
echo -e "${GREEN}Latest commit: $COMMIT_HASH${NC}"
echo -e "${CYAN}Author: $AUTHOR${NC}"
echo -e "${CYAN}Message: \"$COMMIT_MSG\"${NC}"
echo ""

# Step 4: Install dependencies
echo -e "${YELLOW}[4/6] Installing dependencies...${NC}"
if [ ! -d "node_modules" ]; then
    npm ci
else
    echo "Dependencies already installed (updating...)"
    npm ci
fi
echo ""

# Step 5: Build application
echo -e "${YELLOW}[5/6] Building Next.js application...${NC}"
npm run build
BUILD_TIME=$(date '+%Y-%m-%d %H:%M:%S')
echo -e "${GREEN}Build complete at $BUILD_TIME${NC}"
echo ""

# Step 6: Deploy to S3
echo -e "${YELLOW}[6/6] Deploying to S3...${NC}"
cd out
awslocal s3 sync . "s3://$DEPLOYMENT_BUCKET/" --delete

FILE_COUNT=$(awslocal s3 ls "s3://$DEPLOYMENT_BUCKET/" --recursive | wc -l | tr -d ' ')
echo -e "${GREEN}Deployed $FILE_COUNT files to S3${NC}"
echo ""

# Log deployment
DEPLOYMENT_LOG="$PROJECT_ROOT/deployments.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') | $COMMIT_HASH | $AUTHOR | $COMMIT_MSG" >> "$DEPLOYMENT_LOG"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Deployed commit: ${CYAN}$COMMIT_HASH${NC}"
echo -e "By: ${CYAN}$AUTHOR${NC}"
echo -e "Website URL: ${YELLOW}$WEBSITE_ENDPOINT${NC}"
echo ""
echo -e "View your website:"
echo -e "  ${CYAN}curl $WEBSITE_ENDPOINT${NC}"
echo -e "  ${CYAN}open $WEBSITE_ENDPOINT${NC}"
echo ""
echo -e "Deployment logged to: ${CYAN}$DEPLOYMENT_LOG${NC}"
echo ""
