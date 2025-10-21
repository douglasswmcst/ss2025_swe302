#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Practical 6 - Status Check${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Terraform has been applied
if [ ! -f "$TERRAFORM_DIR/terraform.tfstate" ]; then
    echo -e "${RED}Infrastructure not deployed yet. Run ./scripts/deploy.sh first.${NC}"
    exit 1
fi

cd "$TERRAFORM_DIR"

# Get infrastructure details
echo -e "${YELLOW}Infrastructure Details:${NC}"
echo "----------------------------------------"
terraform output
echo ""

# Get bucket details
DEPLOYMENT_BUCKET=$(terraform output -raw deployment_bucket_name 2>/dev/null || echo "")
WEBSITE_ENDPOINT=$(terraform output -raw deployment_website_endpoint 2>/dev/null || echo "")

if [ -z "$DEPLOYMENT_BUCKET" ]; then
    echo -e "${RED}Failed to retrieve bucket name${NC}"
    exit 1
fi

# Check S3 deployment bucket contents
echo -e "${YELLOW}Deployment Bucket Contents:${NC}"
echo "----------------------------------------"
OBJECT_COUNT=$(awslocal s3 ls "s3://$DEPLOYMENT_BUCKET" --recursive 2>/dev/null | wc -l | tr -d ' ')

if [ "$OBJECT_COUNT" -gt 0 ]; then
    echo -e "${GREEN}$OBJECT_COUNT files deployed${NC}"
    echo ""
    echo "Recent files:"
    awslocal s3 ls "s3://$DEPLOYMENT_BUCKET" --recursive | sort -k3,4 | tail -10
    echo ""

    # Calculate total size
    TOTAL_SIZE=$(awslocal s3 ls "s3://$DEPLOYMENT_BUCKET" --recursive --summarize 2>/dev/null | grep "Total Size" | awk '{print $3}')
    if [ -n "$TOTAL_SIZE" ]; then
        # Convert bytes to human readable
        if [ "$TOTAL_SIZE" -gt 1048576 ]; then
            SIZE_MB=$(echo "scale=2; $TOTAL_SIZE / 1048576" | bc)
            echo -e "Total Size: ${CYAN}${SIZE_MB} MB${NC}"
        elif [ "$TOTAL_SIZE" -gt 1024 ]; then
            SIZE_KB=$(echo "scale=2; $TOTAL_SIZE / 1024" | bc)
            echo -e "Total Size: ${CYAN}${SIZE_KB} KB${NC}"
        else
            echo -e "Total Size: ${CYAN}${TOTAL_SIZE} bytes${NC}"
        fi
    fi
else
    echo -e "${YELLOW}No files deployed yet${NC}"
    echo ""
    echo "To deploy, run: ${CYAN}./scripts/deploy.sh${NC}"
fi

echo ""

# Website status
echo -e "${YELLOW}Website Status:${NC}"
echo "----------------------------------------"
if [ -n "$WEBSITE_ENDPOINT" ]; then
    echo -e "Endpoint: ${GREEN}$WEBSITE_ENDPOINT${NC}"
    echo ""

    # Try to fetch the website
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$WEBSITE_ENDPOINT" 2>/dev/null || echo "000")
    if [ "$HTTP_STATUS" = "200" ]; then
        echo -e "Status: ${GREEN}✓ Website is accessible (HTTP $HTTP_STATUS)${NC}"
        echo ""
        echo "Preview (first 5 lines):"
        curl -s "$WEBSITE_ENDPOINT" 2>/dev/null | head -5
    else
        echo -e "Status: ${YELLOW}⚠ Website not accessible yet (HTTP $HTTP_STATUS)${NC}"

        if [ "$OBJECT_COUNT" -eq 0 ]; then
            echo -e "${YELLOW}Reason: No files deployed yet${NC}"
        else
            echo -e "${YELLOW}Checking bucket configuration...${NC}"
            # Check if index.html exists
            if awslocal s3 ls "s3://$DEPLOYMENT_BUCKET/index.html" &>/dev/null; then
                echo -e "${GREEN}✓ index.html exists${NC}"
            else
                echo -e "${RED}✗ index.html not found${NC}"
            fi
        fi
    fi
else
    echo "Website endpoint not available"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Useful commands:"
echo -e "  List all files: ${YELLOW}awslocal s3 ls s3://$DEPLOYMENT_BUCKET --recursive${NC}"
echo -e "  View website: ${YELLOW}curl $WEBSITE_ENDPOINT${NC}"
echo -e "  Re-deploy: ${YELLOW}./scripts/deploy.sh${NC}"
echo -e "  Open in browser: ${YELLOW}open $WEBSITE_ENDPOINT${NC}"
echo ""
