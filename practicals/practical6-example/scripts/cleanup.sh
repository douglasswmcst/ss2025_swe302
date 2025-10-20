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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Practical 6 - Cleanup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Destroy Terraform infrastructure
if [ -f "$TERRAFORM_DIR/terraform.tfstate" ]; then
    echo -e "${YELLOW}Destroying Terraform infrastructure...${NC}"
    cd "$TERRAFORM_DIR"
    terraform destroy -auto-approve
    echo -e "${GREEN}Terraform infrastructure destroyed${NC}"
    echo ""
else
    echo -e "${YELLOW}No Terraform state found, skipping destroy${NC}"
    echo ""
fi

# Step 2: Stop and remove LocalStack container
echo -e "${YELLOW}Stopping LocalStack...${NC}"
cd "$PROJECT_ROOT"
docker-compose down
echo -e "${GREEN}LocalStack stopped${NC}"
echo ""

# Step 3: Clean up generated files
echo -e "${YELLOW}Cleaning up generated files...${NC}"
rm -f "$PROJECT_ROOT/nextjs-app.zip"
rm -rf "$PROJECT_ROOT/nextjs-app/out"
rm -rf "$PROJECT_ROOT/nextjs-app/.next"
echo -e "${GREEN}Generated files removed${NC}"
echo ""

# Step 4: Optional - Remove persisted data
read -p "Remove persisted LocalStack data? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Removing localstack-data directory...${NC}"
    rm -rf "$PROJECT_ROOT/localstack-data"
    echo -e "${GREEN}Data removed${NC}"
    echo ""
fi

# Step 5: Optional - Remove Terraform state files
read -p "Remove Terraform state files? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Removing Terraform state files...${NC}"
    rm -rf "$TERRAFORM_DIR/.terraform"
    rm -f "$TERRAFORM_DIR/.terraform.lock.hcl"
    rm -f "$TERRAFORM_DIR/terraform.tfstate"
    rm -f "$TERRAFORM_DIR/terraform.tfstate.backup"
    echo -e "${GREEN}Terraform state removed${NC}"
    echo ""
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Cleanup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "To start fresh, run: ${YELLOW}./scripts/deploy.sh${NC}"
echo ""
