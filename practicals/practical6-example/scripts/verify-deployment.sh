#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Deployment Verification${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

cd "$TERRAFORM_DIR"
WEBSITE_ENDPOINT=$(terraform output -raw deployment_website_endpoint)
DEPLOYMENT_BUCKET=$(terraform output -raw deployment_bucket_name)

# Check 1: Website accessibility
echo -e "${YELLOW}1. Checking website accessibility...${NC}"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$WEBSITE_ENDPOINT" 2>/dev/null || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "   ${GREEN}✓ Website is accessible (HTTP $HTTP_STATUS)${NC}"
else
    echo -e "   ${RED}✗ Website returned HTTP $HTTP_STATUS${NC}"
    exit 1
fi

# Check 2: File count
echo -e "${YELLOW}2. Checking deployed files...${NC}"
FILE_COUNT=$(awslocal s3 ls "s3://$DEPLOYMENT_BUCKET/" --recursive 2>/dev/null | wc -l | tr -d ' ')
if [ "$FILE_COUNT" -gt 0 ]; then
    echo -e "   ${GREEN}✓ $FILE_COUNT files deployed${NC}"
else
    echo -e "   ${RED}✗ No files found in deployment bucket${NC}"
    exit 1
fi

# Check 3: index.html exists
echo -e "${YELLOW}3. Checking index.html...${NC}"
if awslocal s3 ls "s3://$DEPLOYMENT_BUCKET/index.html" &>/dev/null; then
    echo -e "   ${GREEN}✓ index.html exists${NC}"
else
    echo -e "   ${RED}✗ index.html not found${NC}"
    exit 1
fi

# Check 4: Content verification
echo -e "${YELLOW}4. Checking page content...${NC}"
CONTENT=$(curl -s "$WEBSITE_ENDPOINT" 2>/dev/null | head -10)
if echo "$CONTENT" | grep -q "Practical 6"; then
    echo -e "   ${GREEN}✓ Page contains expected content${NC}"
else
    echo -e "   ${YELLOW}⚠ Page content may not be correct${NC}"
fi

# Check 5: Latest deployment info
echo -e "${YELLOW}5. Deployment information:${NC}"
if [ -f "$PROJECT_ROOT/deployments.log" ]; then
    LAST_DEPLOYMENT=$(tail -1 "$PROJECT_ROOT/deployments.log")
    echo -e "   ${CYAN}$LAST_DEPLOYMENT${NC}"
else
    echo -e "   ${YELLOW}No deployment log found${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All Checks Passed! ✓${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Website: ${CYAN}$WEBSITE_ENDPOINT${NC}"
echo -e "Files deployed: ${CYAN}$FILE_COUNT${NC}"
echo ""
