#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

GITHUB_REPO="${GITHUB_REPO:-YOUR_USERNAME/practical6-nextjs-app}"
INTERVAL="${INTERVAL:-60}"  # Check every 60 seconds

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Auto-Deploy Watcher${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Watching repository: ${CYAN}$GITHUB_REPO${NC}"
echo -e "Check interval: ${CYAN}${INTERVAL}s${NC}"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

LAST_COMMIT=""

while true; do
    # Fetch latest commit hash from GitHub
    LATEST_COMMIT=$(git ls-remote "https://github.com/$GITHUB_REPO.git" HEAD 2>/dev/null | cut -f1 | cut -c1-7)

    if [ -z "$LATEST_COMMIT" ]; then
        echo -e "${YELLOW}Could not fetch commit from GitHub. Check repository URL.${NC}"
        sleep "$INTERVAL"
        continue
    fi

    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    if [ "$LATEST_COMMIT" != "$LAST_COMMIT" ] && [ -n "$LAST_COMMIT" ]; then
        echo ""
        echo -e "${GREEN}[$TIMESTAMP] New commit detected: $LATEST_COMMIT${NC}"
        echo -e "${YELLOW}Starting deployment...${NC}"
        echo ""

        if "$SCRIPT_DIR/deploy-from-github.sh"; then
            echo ""
            echo -e "${GREEN}Deployment successful!${NC}"
        else
            echo ""
            echo -e "${RED}Deployment failed!${NC}"
        fi

        LAST_COMMIT="$LATEST_COMMIT"
    elif [ -z "$LAST_COMMIT" ]; then
        LAST_COMMIT="$LATEST_COMMIT"
        echo -e "${CYAN}[$TIMESTAMP] Initial commit: $LAST_COMMIT${NC}"
    else
        echo -e "${CYAN}[$TIMESTAMP] No changes (current: $LATEST_COMMIT)${NC}"
    fi

    sleep "$INTERVAL"
done
