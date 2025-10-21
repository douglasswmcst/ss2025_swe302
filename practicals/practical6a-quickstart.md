# Practical 6a - Quick Start Guide

This guide helps you set up your GitHub repository for Practical 6a.

## Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `practical6-nextjs-app`
3. Description: "Next.js app deployed to LocalStack S3"
4. Choose Public or Private
5. **Do NOT** initialize with README, .gitignore, or license
6. Click "Create repository"

## Step 2: Prepare Your Next.js App

```bash
# Navigate to practicals directory
cd practicals

# Create a directory for your GitHub-ready app
mkdir practical6a-app
cd practical6a-app

# Copy the Next.js application
cp -r ../practical6-example/nextjs-app/* ./

# Create .gitignore
cat > .gitignore <<'EOF'
# Dependencies
node_modules/

# Build outputs
.next/
out/
*.zip

# Logs
*.log
npm-debug.log*

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local
.env.*.local
EOF
```

## Step 3: Initialize Git and Push

```bash
# Initialize Git repository
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: Next.js app for S3 deployment"

# Add your GitHub repository as remote
# Replace YOUR_USERNAME with your GitHub username
git remote add origin https://github.com/YOUR_USERNAME/practical6-nextjs-app.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## Step 4: Configure Deployment Script

```bash
# Go back to practical6-example
cd ../practical6-example

# Set your GitHub repository
export GITHUB_REPO="YOUR_USERNAME/practical6-nextjs-app"

# Or edit the script directly
# Open scripts/deploy-from-github.sh
# Change: GITHUB_REPO="${GITHUB_REPO:-YOUR_USERNAME/practical6-nextjs-app}"
```

## Step 5: Test Deployment

```bash
# Ensure LocalStack and infrastructure are running
make setup

# Deploy from GitHub
make deploy-github

# Or use the script directly
./scripts/deploy-from-github.sh

# Verify deployment
make verify
```

## Step 6: Make a Change and Redeploy

```bash
# Go to your GitHub repository directory
cd ../practical6a-app

# Make a change (e.g., edit nextjs-app/app/page.tsx)
# ... make your changes ...

# Commit and push
git add .
git commit -m "Update homepage"
git push origin main

# Deploy the changes
cd ../practical6-example
make deploy-github
```

## Troubleshooting

### Repository URL Issues

If you get authentication errors:

```bash
# Use HTTPS with personal access token
git remote set-url origin https://YOUR_USERNAME:YOUR_TOKEN@github.com/YOUR_USERNAME/practical6-nextjs-app.git

# Or use SSH (if you have SSH keys set up)
git remote set-url origin git@github.com:YOUR_USERNAME/practical6-nextjs-app.git
```

### Script Can't Find Repository

```bash
# Verify the environment variable
echo $GITHUB_REPO

# Set it explicitly
export GITHUB_REPO="your-username/practical6-nextjs-app"

# Verify it's set correctly
./scripts/deploy-from-github.sh
```

### Permission Denied

Make sure scripts are executable:

```bash
chmod +x scripts/*.sh
```

## Next Steps

Once you have the basic deployment working:

1. Try the **watch** feature: `make watch`
2. Practice **rollback**: `make rollback COMMIT=abc123`
3. Read the full [Practical 6a guide](./practical6a.md) for more exercises

## Quick Reference

```bash
# Deploy from GitHub
make deploy-github

# Verify deployment
make verify

# Rollback to specific commit
make rollback COMMIT=abc1234

# Watch for changes (auto-deploy)
make watch

# Check deployment logs
cat deployments.log
```
