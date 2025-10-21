# Practical 6a: Git-based Deployment Workflow with GitHub and LocalStack

**Learning Outcomes:**
1. Create and manage a GitHub repository for infrastructure code
2. Implement a Git-based deployment workflow
3. Automate deployments from GitHub to LocalStack S3
4. Understand CI/CD concepts and deployment automation

**Duration:** 1-2 hours

**Prerequisites:** Complete [Practical 6](./practical6.md) first

## Overview

In this practical, you'll extend your Infrastructure as Code knowledge by implementing a Git-based deployment workflow. You'll push your Next.js application to GitHub and create automation scripts that deploy directly from your repository to LocalStack S3.

### What You'll Build

Building on Practical 6, you'll add:
- **GitHub Repository**: Version-controlled application code
- **Deployment Automation**: Scripts that deploy from GitHub
- **Git Workflow**: Proper branching and deployment strategies
- **Deployment Tracking**: Monitor and verify GitHub-based deployments

### Technologies

- **Git**: Version control system
- **GitHub**: Code hosting and collaboration platform
- **Bash Scripts**: Deployment automation
- **Terraform**: Infrastructure as Code (from Practical 6)
- **LocalStack**: Local AWS emulator

## Why Git-based Deployments?

Traditional deployment workflows involve:
1. Developer makes changes locally
2. Manually builds and packages application
3. Manually uploads to server/cloud

**Git-based deployment** improves this:
1. Developer commits changes to Git
2. Push to GitHub triggers automated deployment
3. Deployment script pulls latest code and deploys
4. Version history and rollback capabilities built-in

### Benefits

- **Version Control**: Every deployment is tracked
- **Reproducibility**: Deploy exact same code anywhere
- **Collaboration**: Multiple developers can contribute
- **Rollback**: Easy to revert to previous versions
- **Automation**: Reduce manual errors

## Part 1: Setting Up GitHub Repository

### Step 1: Create a GitHub Repository

1. Go to [GitHub](https://github.com) and sign in
2. Click the "+" icon → "New repository"
3. Configure your repository:
   - **Repository name**: `practical6-nextjs-app`
   - **Description**: "Next.js application deployed to LocalStack S3"
   - **Visibility**: Public or Private (your choice)
   - **Initialize**: Don't add README, .gitignore, or license yet
4. Click "Create repository"

### Step 2: Prepare Your Local Repository

Navigate to your practical6-example directory:

```bash
cd practicals/practical6-example
```

Check current Git status:

```bash
git status
```

If this is already a Git repository (part of the course repo), you'll need to work with a subdirectory. Let's create a separate repository for just the Next.js app:

```bash
# Create a new directory for the GitHub-deployable version
cd ..
mkdir practical6a-example
cd practical6a-example

# Copy the Next.js app
cp -r ../practical6-example/nextjs-app ./

# Copy necessary files
cp ../practical6-example/.gitignore ./
```

### Step 3: Initialize Git Repository

```bash
# Initialize Git
git init

# Create .gitignore if not present
cat > .gitignore <<EOF
# Node.js
node_modules/
.next/
out/
*.log

# Build artifacts
*.zip

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local
EOF

# Add files
git add .

# Initial commit
git commit -m "Initial commit: Next.js app for S3 deployment"
```

### Step 4: Connect to GitHub

```bash
# Add GitHub as remote (replace with your repo URL)
git remote add origin https://github.com/YOUR_USERNAME/practical6-nextjs-app.git

# Verify remote
git remote -v

# Push to GitHub
git branch -M main
git push -u origin main
```

**Verify**: Visit your GitHub repository in a browser. You should see your Next.js application code.

## Part 2: Creating Deployment Scripts

### Understanding the Deployment Flow

```
GitHub Repository                    Developer Machine                LocalStack
       │                                    │                              │
       │  1. Developer pushes code          │                              │
       │  <─────────────────────────        │                              │
       │                                    │                              │
       │  2. Run deployment script          │                              │
       │     ./deploy-from-github.sh        │                              │
       │                                    │                              │
       │  3. Clone/pull latest      ────────┤                              │
       │  <─────────────────────────        │                              │
       │                                    │                              │
       │                                    │  4. Build Next.js            │
       │                                    │     npm run build            │
       │                                    │                              │
       │                                    │  5. Deploy to S3             │
       │                                    │  ──────────────────────────> │
       │                                    │                              │
```

### Step 1: Create Deployment Script

Go back to your practical6-example directory:

```bash
cd ../practical6-example
```

Create a new deployment script:

```bash
cat > scripts/deploy-from-github.sh <<'EOF'
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
echo -e "${GREEN}Latest commit: $COMMIT_HASH${NC}"
echo -e "${CYAN}\"$COMMIT_MSG\"${NC}"
echo ""

# Step 4: Install dependencies
echo -e "${YELLOW}[4/6] Installing dependencies...${NC}"
if [ ! -d "node_modules" ]; then
    npm ci
else
    echo "Dependencies already installed"
fi
echo ""

# Step 5: Build application
echo -e "${YELLOW}[5/6] Building Next.js application...${NC}"
npm run build
echo -e "${GREEN}Build complete${NC}"
echo ""

# Step 6: Deploy to S3
echo -e "${YELLOW}[6/6] Deploying to S3...${NC}"
cd out
awslocal s3 sync . "s3://$DEPLOYMENT_BUCKET/" --delete

FILE_COUNT=$(awslocal s3 ls "s3://$DEPLOYMENT_BUCKET/" --recursive | wc -l | tr -d ' ')
echo -e "${GREEN}Deployed $FILE_COUNT files to S3${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Deployed commit: ${CYAN}$COMMIT_HASH${NC}"
echo -e "Website URL: ${YELLOW}$WEBSITE_ENDPOINT${NC}"
echo ""
echo -e "View your website:"
echo -e "  ${CYAN}curl $WEBSITE_ENDPOINT${NC}"
echo ""
EOF

chmod +x scripts/deploy-from-github.sh
```

### Step 2: Configure the Script

Edit the script to add your GitHub repository URL:

```bash
# Open the script
code scripts/deploy-from-github.sh

# Or use sed to replace
GITHUB_USERNAME="your-github-username"
sed -i.bak "s/YOUR_USERNAME/$GITHUB_USERNAME/" scripts/deploy-from-github.sh
```

### Step 3: Test the Deployment

```bash
# Set your repository (or export GITHUB_REPO environment variable)
export GITHUB_REPO="your-username/practical6-nextjs-app"

# Run the deployment
./scripts/deploy-from-github.sh
```

## Part 3: Making Changes and Redeploying

### Workflow: Make a Change

1. **Clone your repository** (if you haven't already):
   ```bash
   cd ~/projects  # or your preferred directory
   git clone https://github.com/YOUR_USERNAME/practical6-nextjs-app.git
   cd practical6-nextjs-app
   ```

2. **Make a change** to the application:
   ```bash
   # Edit the main page
   code nextjs-app/app/page.tsx

   # For example, change the title
   ```

3. **Commit and push**:
   ```bash
   git add .
   git commit -m "Update homepage title"
   git push origin main
   ```

4. **Deploy from GitHub**:
   ```bash
   cd ../practical6-example
   ./scripts/deploy-from-github.sh
   ```

5. **Verify the changes**:
   ```bash
   curl $(cd terraform && terraform output -raw deployment_website_endpoint)
   ```

### Exercise 1: Feature Branch Workflow

Practice a proper Git workflow:

```bash
# In your GitHub repository directory
cd ~/projects/practical6-nextjs-app

# Create a feature branch
git checkout -b feature/add-footer

# Make changes
echo "export default function Footer() { return <footer>© 2025 Practical 6</footer> }" > nextjs-app/app/components/Footer.tsx

# Update page to use footer
# (edit nextjs-app/app/page.tsx to import and use Footer)

# Commit changes
git add .
git commit -m "Add footer component"

# Push feature branch
git push origin feature/add-footer

# Merge to main (after review)
git checkout main
git merge feature/add-footer
git push origin main

# Deploy
cd ../practical6-example
./scripts/deploy-from-github.sh
```

## Part 4: Deployment Automation Enhancements

### Step 1: Add Deployment Verification

Create a verification script:

```bash
cat > scripts/verify-deployment.sh <<'EOF'
#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

cd "$TERRAFORM_DIR"
WEBSITE_ENDPOINT=$(terraform output -raw deployment_website_endpoint)
DEPLOYMENT_BUCKET=$(terraform output -raw deployment_bucket_name)

echo "Deployment Verification"
echo "======================="
echo ""

# Check website accessibility
echo "1. Checking website accessibility..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$WEBSITE_ENDPOINT")

if [ "$HTTP_STATUS" = "200" ]; then
    echo "   ✓ Website is accessible (HTTP $HTTP_STATUS)"
else
    echo "   ✗ Website returned HTTP $HTTP_STATUS"
    exit 1
fi

# Check file count
echo "2. Checking deployed files..."
FILE_COUNT=$(awslocal s3 ls "s3://$DEPLOYMENT_BUCKET/" --recursive | wc -l | tr -d ' ')
echo "   ✓ $FILE_COUNT files deployed"

# Check index.html exists
echo "3. Checking index.html..."
if awslocal s3 ls "s3://$DEPLOYMENT_BUCKET/index.html" &>/dev/null; then
    echo "   ✓ index.html exists"
else
    echo "   ✗ index.html not found"
    exit 1
fi

echo ""
echo "All checks passed! ✓"
echo "Website: $WEBSITE_ENDPOINT"
EOF

chmod +x scripts/verify-deployment.sh
```

### Step 2: Add Rollback Capability

Create a rollback script:

```bash
cat > scripts/rollback.sh <<'EOF'
#!/bin/bash

set -e

CLONE_DIR="${CLONE_DIR:-/tmp/practical6-deploy}"
COMMIT_HASH="$1"

if [ -z "$COMMIT_HASH" ]; then
    echo "Usage: ./scripts/rollback.sh <commit-hash>"
    echo ""
    echo "Recent commits:"
    cd "$CLONE_DIR" 2>/dev/null && git log --oneline -5 || echo "Repository not found at $CLONE_DIR"
    exit 1
fi

echo "Rolling back to commit: $COMMIT_HASH"
cd "$CLONE_DIR"
git checkout "$COMMIT_HASH"

# Rebuild and redeploy
npm run build
cd out

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT/terraform"

DEPLOYMENT_BUCKET=$(terraform output -raw deployment_bucket_name)
awslocal s3 sync "$CLONE_DIR/out/" "s3://$DEPLOYMENT_BUCKET/" --delete

echo "Rollback complete!"
echo "Reverted to commit: $COMMIT_HASH"
EOF

chmod +x scripts/rollback.sh
```

### Step 3: Update Makefile

Add GitHub deployment commands to the Makefile:

```bash
cd ../practical6-example

cat >> Makefile <<'EOF'

# GitHub-based deployment commands
deploy-github: ## Deploy from GitHub repository
	@./scripts/deploy-from-github.sh

verify: ## Verify deployment
	@./scripts/verify-deployment.sh

rollback: ## Rollback to previous commit (usage: make rollback COMMIT=abc123)
	@./scripts/rollback.sh $(COMMIT)
EOF
```

## Part 5: Understanding CI/CD Concepts

### What is CI/CD?

**Continuous Integration (CI)**:
- Automatically build and test code when changes are pushed
- Catch errors early
- Ensure code quality

**Continuous Deployment (CD)**:
- Automatically deploy tested code to production
- Faster delivery of features
- Reduce manual deployment errors

### Local vs Cloud CI/CD

**Local (This Practical)**:
- Deploy from GitHub to LocalStack on your machine
- Manual trigger: run deploy script
- Good for: Development, testing, learning

**Cloud CI/CD** (GitHub Actions, GitLab CI, etc):
- Automatic trigger: on push, pull request, etc.
- Runs on cloud servers
- Good for: Production deployments

### Simulating CI/CD Locally

You can create a simple "watch" script that automatically deploys when changes are pushed:

```bash
cat > scripts/watch-and-deploy.sh <<'EOF'
#!/bin/bash

GITHUB_REPO="${GITHUB_REPO:-YOUR_USERNAME/practical6-nextjs-app}"
INTERVAL="${INTERVAL:-60}"  # Check every 60 seconds

echo "Watching GitHub repository: $GITHUB_REPO"
echo "Checking for updates every $INTERVAL seconds"
echo "Press Ctrl+C to stop"
echo ""

LAST_COMMIT=""

while true; do
    # Fetch latest commit hash from GitHub
    LATEST_COMMIT=$(git ls-remote "https://github.com/$GITHUB_REPO.git" HEAD | cut -f1 | cut -c1-7)

    if [ "$LATEST_COMMIT" != "$LAST_COMMIT" ] && [ -n "$LAST_COMMIT" ]; then
        echo "New commit detected: $LATEST_COMMIT"
        echo "Deploying..."
        ./scripts/deploy-from-github.sh
        LAST_COMMIT="$LATEST_COMMIT"
    elif [ -z "$LAST_COMMIT" ]; then
        LAST_COMMIT="$LATEST_COMMIT"
        echo "Initial commit: $LAST_COMMIT"
    fi

    sleep "$INTERVAL"
done
EOF

chmod +x scripts/watch-and-deploy.sh
```

## Part 6: Exercises

### Exercise 1: Multi-Stage Deployment

Create separate environments:

1. Create `dev` and `prod` branches in GitHub
2. Modify deployment script to support environment parameter
3. Deploy dev branch to one S3 bucket, prod to another

### Exercise 2: Deployment Hooks

Add pre-deployment and post-deployment hooks:

```bash
# Create hooks directory
mkdir -p scripts/hooks

# Pre-deployment: Run tests
cat > scripts/hooks/pre-deploy.sh <<'EOF'
#!/bin/bash
echo "Running tests..."
cd "$CLONE_DIR"
npm test
EOF

# Post-deployment: Notify
cat > scripts/hooks/post-deploy.sh <<'EOF'
#!/bin/bash
echo "Deployment complete! Sending notification..."
# Could send email, Slack message, etc.
EOF
```

### Exercise 3: Deployment History

Track deployment history:

```bash
cat > scripts/log-deployment.sh <<'EOF'
#!/bin/bash

LOG_FILE="deployments.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
COMMIT_HASH=$(cd /tmp/practical6-deploy && git rev-parse --short HEAD)
COMMIT_MSG=$(cd /tmp/practical6-deploy && git log -1 --pretty=%B)

echo "$TIMESTAMP | $COMMIT_HASH | $COMMIT_MSG" >> "$LOG_FILE"
echo "Deployment logged"
EOF
```

## Part 7: Best Practices

### Git Workflow Best Practices

1. **Use Feature Branches**
   ```bash
   git checkout -b feature/new-feature
   # make changes
   git commit -m "Add new feature"
   git push origin feature/new-feature
   # create pull request
   ```

2. **Write Good Commit Messages**
   - Use present tense: "Add feature" not "Added feature"
   - Be specific: "Fix navigation bug on mobile" not "Fix bug"
   - Reference issues: "Fix #123: Navigation bug"

3. **Tag Releases**
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

### Deployment Best Practices

1. **Always Test Before Deploying**
   ```bash
   npm test
   npm run build
   # verify build works
   ```

2. **Use Environment Variables**
   ```bash
   export GITHUB_REPO="username/repo"
   export BRANCH="main"
   ./scripts/deploy-from-github.sh
   ```

3. **Keep Deployment History**
   - Log every deployment
   - Track who deployed what and when
   - Enable easy rollback

4. **Automate Verification**
   - Check website is accessible after deployment
   - Verify critical functionality
   - Alert on failures

## Part 8: Troubleshooting

### Issue: Git clone fails

**Symptom**: "Permission denied" or "Repository not found"

**Solution**:
```bash
# Use HTTPS instead of SSH
git clone https://github.com/username/repo.git

# Or configure SSH keys
ssh-keygen -t ed25519 -C "your_email@example.com"
# Add to GitHub: Settings → SSH and GPG keys
```

### Issue: Deployment script can't find repository

**Symptom**: "Repository not found at /tmp/practical6-deploy"

**Solution**:
```bash
# Set correct repository
export GITHUB_REPO="your-username/practical6-nextjs-app"

# Or edit scripts/deploy-from-github.sh
```

### Issue: Build fails during deployment

**Symptom**: "npm run build" fails

**Solution**:
```bash
# Check build locally first
cd /tmp/practical6-deploy
npm ci
npm run build

# Check for missing dependencies
npm install
```

## Learning Checkpoints

By completing this practical, you should be able to:

- [ ] Create and configure a GitHub repository
- [ ] Push code to GitHub using Git commands
- [ ] Write deployment automation scripts
- [ ] Deploy applications from GitHub to S3
- [ ] Implement rollback procedures
- [ ] Understand CI/CD concepts
- [ ] Use feature branch workflows
- [ ] Track and verify deployments
- [ ] Troubleshoot deployment issues

## Conclusion

You've now implemented a Git-based deployment workflow that:
- **Automates** deployments from GitHub
- **Tracks** every deployment with Git history
- **Enables** easy rollback to previous versions
- **Demonstrates** CI/CD principles

### Key Takeaways

- **Git** is essential for modern deployment workflows
- **Automation** reduces errors and saves time
- **Version control** enables safe deployments and rollbacks
- **CI/CD** concepts apply across all platforms and tools

### Next Steps

- Explore GitHub Actions for cloud-based CI/CD
- Implement automated testing in deployment pipeline
- Add deployment notifications (email, Slack)
- Create staging and production environments
- Integrate with monitoring and logging tools

**Congratulations!** You've mastered Git-based deployment workflows and are ready to apply these concepts in real-world projects.
