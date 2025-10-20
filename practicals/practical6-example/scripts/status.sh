#!/bin/bash

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

# Get pipeline name
PIPELINE_NAME=$(terraform output -raw pipeline_name 2>/dev/null || echo "")
WEBSITE_ENDPOINT=$(terraform output -raw deployment_website_endpoint 2>/dev/null || echo "")

if [ -z "$PIPELINE_NAME" ]; then
    echo -e "${RED}Failed to retrieve pipeline name${NC}"
    exit 1
fi

# Check pipeline status
echo -e "${YELLOW}Pipeline Status:${NC}"
echo "----------------------------------------"
PIPELINE_STATE=$(awslocal codepipeline get-pipeline-state --name "$PIPELINE_NAME" 2>/dev/null)

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to get pipeline state${NC}"
    exit 1
fi

# Parse and display stage status
echo "$PIPELINE_STATE" | jq -r '.stageStates[] | "Stage: \(.stageName)\n  Status: \(.latestExecution.status // "Not started")\n"'

# Get latest execution status
LATEST_EXECUTION=$(awslocal codepipeline list-pipeline-executions \
    --pipeline-name "$PIPELINE_NAME" \
    --max-results 1 2>/dev/null)

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${YELLOW}Latest Execution:${NC}"
    echo "----------------------------------------"
    echo "$LATEST_EXECUTION" | jq -r '.pipelineExecutionSummaries[0] | "Execution ID: \(.pipelineExecutionId)\nStatus: \(.status)\nStart Time: \(.startTime // "N/A")\nLast Update: \(.lastUpdateTime // "N/A")"'
fi

# Check CodeBuild status
echo ""
echo -e "${YELLOW}Recent Build Status:${NC}"
echo "----------------------------------------"
BUILD_PROJECT=$(terraform output -raw codebuild_project_name 2>/dev/null)
if [ -n "$BUILD_PROJECT" ]; then
    BUILDS=$(awslocal codebuild list-builds-for-project \
        --project-name "$BUILD_PROJECT" \
        --max-results 1 2>/dev/null)

    if [ $? -eq 0 ]; then
        BUILD_ID=$(echo "$BUILDS" | jq -r '.ids[0] // empty')
        if [ -n "$BUILD_ID" ]; then
            BUILD_INFO=$(awslocal codebuild batch-get-builds --ids "$BUILD_ID" 2>/dev/null)
            echo "$BUILD_INFO" | jq -r '.builds[0] | "Build ID: \(.id)\nStatus: \(.buildStatus // "N/A")\nPhase: \(.currentPhase // "N/A")\nStart Time: \(.startTime // "N/A")"'
        else
            echo "No builds found yet"
        fi
    else
        echo "Unable to retrieve build information"
    fi
else
    echo "Build project name not available"
fi

# Check S3 deployment bucket contents
echo ""
echo -e "${YELLOW}Deployment Bucket Contents:${NC}"
echo "----------------------------------------"
DEPLOYMENT_BUCKET=$(terraform output -raw deployment_bucket_name 2>/dev/null)
if [ -n "$DEPLOYMENT_BUCKET" ]; then
    OBJECT_COUNT=$(awslocal s3 ls "s3://$DEPLOYMENT_BUCKET" --recursive 2>/dev/null | wc -l)
    if [ "$OBJECT_COUNT" -gt 0 ]; then
        echo -e "${GREEN}$OBJECT_COUNT files deployed${NC}"
        echo ""
        echo "Sample files:"
        awslocal s3 ls "s3://$DEPLOYMENT_BUCKET" --recursive | head -10
    else
        echo -e "${YELLOW}No files deployed yet${NC}"
    fi
else
    echo "Deployment bucket name not available"
fi

# Website status
echo ""
echo -e "${YELLOW}Website Status:${NC}"
echo "----------------------------------------"
if [ -n "$WEBSITE_ENDPOINT" ]; then
    echo -e "Endpoint: ${GREEN}$WEBSITE_ENDPOINT${NC}"

    # Try to fetch the website
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$WEBSITE_ENDPOINT" 2>/dev/null || echo "000")
    if [ "$HTTP_STATUS" = "200" ]; then
        echo -e "Status: ${GREEN}✓ Website is accessible (HTTP $HTTP_STATUS)${NC}"
    else
        echo -e "Status: ${YELLOW}⚠ Website not accessible yet (HTTP $HTTP_STATUS)${NC}"
    fi
else
    echo "Website endpoint not available"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Useful commands:"
echo -e "  View build logs: ${YELLOW}awslocal logs tail /aws/codebuild/$BUILD_PROJECT --follow${NC}"
echo -e "  Re-trigger pipeline: ${YELLOW}awslocal codepipeline start-pipeline-execution --name $PIPELINE_NAME${NC}"
echo -e "  View website: ${YELLOW}curl $WEBSITE_ENDPOINT${NC}"
echo ""
