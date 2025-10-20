#!/bin/bash

set -e

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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Security Comparison Report${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if reports exist
SECURE_REPORT="$PROJECT_ROOT/reports/trivy-secure.txt"
INSECURE_REPORT="$PROJECT_ROOT/reports/trivy-insecure.txt"

if [ ! -f "$SECURE_REPORT" ] || [ ! -f "$INSECURE_REPORT" ]; then
    echo -e "${YELLOW}Scan reports not found. Running scans...${NC}"
    echo ""
    "$SCRIPT_DIR/scan.sh" all
    echo ""
fi

# Generate comparison
echo -e "${CYAN}Comparing secure vs insecure configurations...${NC}"
echo ""

# Count findings in secure configuration
echo -e "${GREEN}Secure Configuration (terraform/):${NC}"
echo "----------------------------------------"
if [ -f "$SECURE_REPORT" ]; then
    SECURE_CRITICAL=$(grep -c "CRITICAL" "$SECURE_REPORT" 2>/dev/null || echo "0")
    SECURE_HIGH=$(grep -c "HIGH" "$SECURE_REPORT" 2>/dev/null || echo "0")
    SECURE_MEDIUM=$(grep -c "MEDIUM" "$SECURE_REPORT" 2>/dev/null || echo "0")
    SECURE_LOW=$(grep -c "LOW" "$SECURE_REPORT" 2>/dev/null || echo "0")
    SECURE_TOTAL=$((SECURE_CRITICAL + SECURE_HIGH + SECURE_MEDIUM + SECURE_LOW))

    echo -e "  CRITICAL: $SECURE_CRITICAL"
    echo -e "  HIGH:     $SECURE_HIGH"
    echo -e "  MEDIUM:   $SECURE_MEDIUM"
    echo -e "  LOW:      $SECURE_LOW"
    echo -e "  ${GREEN}Total:    $SECURE_TOTAL${NC}"
else
    SECURE_TOTAL=0
    echo -e "${RED}Report not found${NC}"
fi

echo ""

# Count findings in insecure configuration
echo -e "${RED}Insecure Configuration (terraform-insecure/):${NC}"
echo "----------------------------------------"
if [ -f "$INSECURE_REPORT" ]; then
    INSECURE_CRITICAL=$(grep -c "CRITICAL" "$INSECURE_REPORT" 2>/dev/null || echo "0")
    INSECURE_HIGH=$(grep -c "HIGH" "$INSECURE_REPORT" 2>/dev/null || echo "0")
    INSECURE_MEDIUM=$(grep -c "MEDIUM" "$INSECURE_REPORT" 2>/dev/null || echo "0")
    INSECURE_LOW=$(grep -c "LOW" "$INSECURE_REPORT" 2>/dev/null || echo "0")
    INSECURE_TOTAL=$((INSECURE_CRITICAL + INSECURE_HIGH + INSECURE_MEDIUM + INSECURE_LOW))

    echo -e "  CRITICAL: $INSECURE_CRITICAL"
    echo -e "  HIGH:     $INSECURE_HIGH"
    echo -e "  MEDIUM:   $INSECURE_MEDIUM"
    echo -e "  LOW:      $INSECURE_LOW"
    echo -e "  ${RED}Total:    $INSECURE_TOTAL${NC}"
else
    INSECURE_TOTAL=0
    echo -e "${RED}Report not found${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Impact Analysis${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Calculate difference
DIFF=$((INSECURE_TOTAL - SECURE_TOTAL))
if [ $DIFF -gt 0 ]; then
    PERCENT=$(awk "BEGIN {printf \"%.1f\", ($DIFF / $INSECURE_TOTAL) * 100}")
    echo -e "${GREEN}Security improvements found:${NC}"
    echo -e "  ${YELLOW}$DIFF${NC} fewer issues in secure configuration"
    echo -e "  ${YELLOW}${PERCENT}%${NC} reduction in total findings"
else
    echo -e "${YELLOW}Both configurations have similar security postures${NC}"
fi

echo ""
echo -e "${CYAN}Key Security Features in Secure Configuration:${NC}"
echo "----------------------------------------"
echo "1. Server-side encryption enabled on all S3 buckets"
echo "2. Access logging enabled for deployment bucket"
echo "3. Versioning enabled on source bucket"
echo "4. Least-privilege IAM policies (no wildcards)"
echo "5. Proper resource-level permissions"
echo ""

echo -e "${RED}Common Issues in Insecure Configuration:${NC}"
echo "----------------------------------------"
echo "1. No encryption on S3 buckets"
echo "2. Overly permissive IAM policies (wildcards)"
echo "3. Public write access to S3 buckets"
echo "4. No access logging"
echo "5. No versioning for disaster recovery"
echo "6. Hardcoded credentials"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Detailed Findings${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${GREEN}Secure Configuration Issues:${NC}"
echo "----------------------------------------"
if [ -f "$SECURE_REPORT" ]; then
    grep -A 2 "HIGH\|CRITICAL" "$SECURE_REPORT" | head -20 || echo "No critical or high severity issues found!"
else
    echo "Report not available"
fi

echo ""
echo -e "${RED}Insecure Configuration Issues (sample):${NC}"
echo "----------------------------------------"
if [ -f "$INSECURE_REPORT" ]; then
    grep -A 2 "HIGH\|CRITICAL" "$INSECURE_REPORT" | head -30 || echo "No issues found"
else
    echo "Report not available"
fi

echo ""
echo -e "${CYAN}Learning Points:${NC}"
echo "----------------------------------------"
echo "1. Security scanning should be part of your CI/CD pipeline"
echo "2. Fix high and critical issues before deployment"
echo "3. Use security best practices from the start"
echo "4. Regularly update and scan your infrastructure code"
echo "5. Document why certain findings are accepted (if any)"
echo ""

echo -e "${GREEN}Full reports available at:${NC}"
echo "  Secure:   $SECURE_REPORT"
echo "  Insecure: $INSECURE_REPORT"
echo ""
