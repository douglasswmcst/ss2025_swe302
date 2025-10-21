#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

CLONE_DIR="${CLONE_DIR:-/tmp/practical6-deploy}"
COMMIT_HASH="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

if [ -z "$COMMIT_HASH" ]; then
    echo -e "${RED}Error: No commit hash provided${NC}"
    echo ""
    echo "Usage: $0 <commit-hash>"
    echo ""
    echo -e "${YELLOW}Recent commits:${NC}"
    if [ -d "$CLONE_DIR" ]; then
        cd "$CLONE_DIR" && git log --oneline -10
    else
        echo "Repository not found at $CLONE_DIR"
        echo "Run deploy-from-github.sh first"
    fi
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Rollback Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Rolling back to commit: ${CYAN}$COMMIT_HASH${NC}"
echo ""

# Verify repository exists
if [ ! -d "$CLONE_DIR" ]; then
    echo -e "${RED}Repository not found at $CLONE_DIR${NC}"
    echo "Run deploy-from-github.sh first to clone the repository"
    exit 1
fi

cd "$CLONE_DIR"

# Verify commit exists
if ! git rev-parse "$COMMIT_HASH" &>/dev/null; then
    echo -e "${RED}Commit $COMMIT_HASH not found${NC}"
    echo ""
    echo -e "${YELLOW}Available commits:${NC}"
    git log --oneline -10
    exit 1
fi

# Get commit info
COMMIT_MSG=$(git log -1 --pretty=%B "$COMMIT_HASH")
COMMIT_AUTHOR=$(git log -1 --pretty=%an "$COMMIT_HASH")
COMMIT_DATE=$(git log -1 --pretty=%ad "$COMMIT_HASH")

echo -e "${CYAN}Commit: $COMMIT_HASH${NC}"
echo -e "${CYAN}Author: $COMMIT_AUTHOR${NC}"
echo -e "${CYAN}Date: $COMMIT_DATE${NC}"
echo -e "${CYAN}Message: \"$COMMIT_MSG\"${NC}"
echo ""

# Checkout commit
echo -e "${YELLOW}Checking out commit...${NC}"
git checkout "$COMMIT_HASH"
echo -e "${GREEN}✓ Checked out commit${NC}"
echo ""

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
npm ci
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Build application
echo -e "${YELLOW}Building application...${NC}"
npm run build
echo -e "${GREEN}✓ Build complete${NC}"
echo ""

# Deploy to S3
echo -e "${YELLOW}Deploying to S3...${NC}"
cd "$TERRAFORM_DIR"
DEPLOYMENT_BUCKET=$(terraform output -raw deployment_bucket_name)
WEBSITE_ENDPOINT=$(terraform output -raw deployment_website_endpoint)

cd "$CLONE_DIR/out"
awslocal s3 sync . "s3://$DEPLOYMENT_BUCKET/" --delete

FILE_COUNT=$(awslocal s3 ls "s3://$DEPLOYMENT_BUCKET/" --recursive | wc -l | tr -d ' ')
echo -e "${GREEN}✓ Deployed $FILE_COUNT files to S3${NC}"
echo ""

# Log rollback
DEPLOYMENT_LOG="$PROJECT_ROOT/deployments.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') | ROLLBACK to $COMMIT_HASH | $COMMIT_AUTHOR | $COMMIT_MSG" >> "$DEPLOYMENT_LOG"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Rollback Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Reverted to commit: ${CYAN}$COMMIT_HASH${NC}"
echo -e "Website URL: ${YELLOW}$WEBSITE_ENDPOINT${NC}"
echo ""
echo -e "Verify the rollback:"
echo -e "  ${CYAN}curl $WEBSITE_ENDPOINT${NC}"
echo ""
echo -e "${YELLOW}Note: Repository is in detached HEAD state${NC}"
echo -e "To return to latest code: ${CYAN}cd $CLONE_DIR && git checkout main${NC}"
echo ""
