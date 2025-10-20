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
echo -e "${BLUE}Trivy Security Scanning${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Trivy is installed
if ! command -v trivy &> /dev/null; then
    echo -e "${RED}Error: Trivy is not installed${NC}"
    echo ""
    echo "Install Trivy:"
    echo "  macOS:   brew install trivy"
    echo "  Linux:   https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
    echo ""
    exit 1
fi

# Get Trivy version
TRIVY_VERSION=$(trivy --version | head -1)
echo -e "${CYAN}Using $TRIVY_VERSION${NC}"
echo ""

# Default scan target
SCAN_TARGET="${1:-terraform}"

case $SCAN_TARGET in
    "terraform"|"secure")
        echo -e "${YELLOW}Scanning secure Terraform configuration...${NC}"
        SCAN_DIR="$PROJECT_ROOT/terraform"
        OUTPUT_FILE="$PROJECT_ROOT/reports/trivy-secure.txt"
        ;;
    "insecure"|"terraform-insecure")
        echo -e "${YELLOW}Scanning insecure Terraform configuration...${NC}"
        SCAN_DIR="$PROJECT_ROOT/terraform-insecure"
        OUTPUT_FILE="$PROJECT_ROOT/reports/trivy-insecure.txt"
        ;;
    "all")
        echo -e "${YELLOW}Scanning all Terraform configurations...${NC}"
        "$0" terraform
        echo ""
        "$0" insecure
        exit 0
        ;;
    *)
        echo -e "${RED}Unknown scan target: $SCAN_TARGET${NC}"
        echo ""
        echo "Usage: $0 [terraform|insecure|all]"
        echo ""
        echo "Options:"
        echo "  terraform  - Scan secure terraform/ directory (default)"
        echo "  insecure   - Scan terraform-insecure/ directory"
        echo "  all        - Scan both directories"
        exit 1
        ;;
esac

# Create reports directory
mkdir -p "$PROJECT_ROOT/reports"

# Run Trivy scan
echo -e "${CYAN}Scanning: $SCAN_DIR${NC}"
echo ""

# Run scan and capture output
trivy config \
    --config "$PROJECT_ROOT/trivy.yaml" \
    --format table \
    --severity CRITICAL,HIGH,MEDIUM,LOW \
    "$SCAN_DIR" | tee "$OUTPUT_FILE"

SCAN_EXIT_CODE=${PIPESTATUS[0]}

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Scan Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Report saved to: ${CYAN}$OUTPUT_FILE${NC}"

# Count findings by severity
if [ -f "$OUTPUT_FILE" ]; then
    echo ""
    echo -e "${YELLOW}Finding Summary:${NC}"
    echo "----------------------------------------"

    CRITICAL=$(grep -c "CRITICAL" "$OUTPUT_FILE" 2>/dev/null || echo "0")
    HIGH=$(grep -c "HIGH" "$OUTPUT_FILE" 2>/dev/null || echo "0")
    MEDIUM=$(grep -c "MEDIUM" "$OUTPUT_FILE" 2>/dev/null || echo "0")
    LOW=$(grep -c "LOW" "$OUTPUT_FILE" 2>/dev/null || echo "0")

    echo -e "  ${RED}CRITICAL:${NC} $CRITICAL"
    echo -e "  ${YELLOW}HIGH:${NC}     $HIGH"
    echo -e "  ${BLUE}MEDIUM:${NC}   $MEDIUM"
    echo -e "  ${GREEN}LOW:${NC}      $LOW"
    echo ""

    TOTAL=$((CRITICAL + HIGH + MEDIUM + LOW))
    if [ "$TOTAL" -eq 0 ]; then
        echo -e "${GREEN}No security issues found!${NC}"
    else
        echo -e "Total findings: ${YELLOW}$TOTAL${NC}"
    fi
fi

echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "  1. Review findings in the report above"
echo "  2. Compare secure vs insecure: ./scripts/compare-security.sh"
echo "  3. Fix issues and re-scan"
echo ""

exit $SCAN_EXIT_CODE
