# Practical 6 - Infrastructure as Code with Terraform

This example demonstrates deploying a Next.js application to LocalStack AWS using Terraform for infrastructure management and S3 for static website hosting.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         LocalStack                           │
│                                                               │
│  Developer Machine               S3 Buckets                  │
│  ┌──────────────┐                                            │
│  │              │       ┌────────────────┐                   │
│  │  Next.js     │──────>│  Deployment    │                   │
│  │  Build       │ sync  │  Bucket        │                   │
│  │  (local)     │       │  (Website)     │                   │
│  │              │       └────────────────┘                   │
│  └──────────────┘                │                           │
│                                   │                           │
│                           ┌───────┴────────┐                 │
│                           │                │                 │
│                    ┌──────▼──────┐  ┌──────▼──────┐          │
│                    │   Public    │  │    Logs     │          │
│                    │   Website   │  │   Bucket    │          │
│                    └─────────────┘  └─────────────┘          │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Components

### Infrastructure (Terraform)
- **S3 Deployment Bucket**: Hosts the static website with public read access
- **S3 Logs Bucket**: Stores access logs for the deployment bucket
- **Bucket Policies**: Configured for public website access
- **Server-Side Encryption**: AES256 encryption enabled on all buckets

### Application
- **Next.js 14**: Modern React framework configured for static export
- **Static Site**: Built locally and deployed to S3 via AWS CLI

### Workflow
1. **Local Build**: Next.js app is built on your machine
2. **Terraform Deploy**: Infrastructure is provisioned in LocalStack
3. **S3 Sync**: Static files are synced to the deployment bucket
4. **Website Access**: Site is accessible via S3 website endpoint

## Prerequisites

### Required Software

1. **Docker and Docker Compose**
   - **macOS**: [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)
   - **Windows**: [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
   - **Linux**: [Docker Engine](https://docs.docker.com/engine/install/) + [Docker Compose](https://docs.docker.com/compose/install/)

2. **Terraform** (>= 1.0)
   - **macOS**: `brew install terraform`
   - **Windows**: `choco install terraform` or download from [terraform.io](https://www.terraform.io/downloads)
   - **Linux**: Use official HashiCorp repository or download binary

3. **terraform-local (tflocal)** - Wrapper for Terraform with LocalStack
   - **All platforms**: `pip install terraform-local`
   - **What it does**: Automatically configures Terraform to use LocalStack endpoints
   - **Usage**: Use `tflocal` instead of `terraform` commands

4. **Node.js** (>= 18)
   - **macOS**: `brew install node`
   - **Windows**: Download from [nodejs.org](https://nodejs.org/) or `choco install nodejs`
   - **Linux**: Use NodeSource repository or package manager

5. **AWS CLI** with `awslocal` wrapper
   - **All platforms**: `pip install awscli awscli-local`

6. **Trivy** (Security Scanner)
   - **macOS**: `brew install trivy`
   - **Windows**: `choco install trivy` or download from [GitHub](https://github.com/aquasecurity/trivy/releases)
   - **Linux**: Use official Trivy repository or download binary

7. **Make** (optional, for convenience commands)
   - **macOS**: Pre-installed
   - **Windows**: `choco install make` or use Git Bash
   - **Linux**: `sudo apt-get install build-essential` (Debian/Ubuntu)

## Quick Start

### Option 1: Using Make (Recommended)

```bash
# Initialize dependencies
make init

# Deploy everything (infrastructure + application)
make deploy

# Check status
make status

# View website
make website
# or manually:
curl $(cd terraform && terraform output -raw deployment_website_endpoint)
```

### Option 2: Using Scripts

```bash
# 1. Install Next.js dependencies
cd nextjs-app
npm ci
cd ..

# 2. Deploy infrastructure and application
./scripts/deploy.sh

# 3. Check deployment status
./scripts/status.sh

# 4. Clean up when done
./scripts/cleanup.sh
```

## Step-by-Step Walkthrough

### 1. Start LocalStack

```bash
./scripts/setup.sh
# or
make setup
```

This starts LocalStack with the required AWS services:
- S3
- IAM
- CloudWatch Logs
- STS

### 2. Build Next.js Application

```bash
cd nextjs-app
npm ci
npm run build
```

The build creates a static export in the `out/` directory.

### 3. Deploy Infrastructure

```bash
cd terraform
tflocal init
tflocal plan
tflocal apply
```

This creates:
- 2 S3 buckets (deployment, logs)
- Bucket policies for public access
- Website configuration
- Server-side encryption

### 4. Deploy Application to S3

```bash
# Get bucket name from Terraform outputs
DEPLOYMENT_BUCKET=$(cd terraform && terraform output -raw deployment_bucket_name)

# Sync files to S3
awslocal s3 sync nextjs-app/out/ s3://$DEPLOYMENT_BUCKET/ --delete
```

### 5. Access Website

```bash
# Get website endpoint
WEBSITE=$(cd terraform && terraform output -raw deployment_website_endpoint)

# Open in browser or curl
curl $WEBSITE
open $WEBSITE  # macOS
```

## Project Structure

```
practical6-example/
├── docker-compose.yml          # LocalStack configuration
├── Makefile                    # Convenience commands
├── README.md                   # This file
│
├── init-scripts/
│   └── 01-setup.sh            # LocalStack initialization script
│
├── scripts/
│   ├── setup.sh               # Start LocalStack
│   ├── deploy.sh              # Full deployment automation
│   ├── status.sh              # Check deployment status
│   ├── cleanup.sh             # Clean up everything
│   ├── scan.sh                # Run Trivy security scans
│   └── compare-security.sh    # Compare secure vs insecure configs
│
├── nextjs-app/
│   ├── app/                   # Next.js application
│   ├── next.config.js         # Configured for static export
│   └── package.json
│
├── terraform/
│   ├── main.tf                # Provider and backend configuration
│   ├── variables.tf           # Input variables
│   ├── s3.tf                  # S3 bucket definitions
│   ├── iam.tf                 # IAM examples (commented out)
│   └── outputs.tf             # Output values
│
└── terraform-insecure/        # Insecure examples for security learning
    ├── s3-insecure.tf
    ├── iam-insecure.tf
    └── README.md
```

## Terraform Outputs

After applying Terraform, you'll see these useful outputs:

```
deployment_bucket_name       - Name of the deployment S3 bucket
logs_bucket_name             - Name of the logs S3 bucket
deployment_website_endpoint  - Website URL
deploy_command               - Command to deploy application
list_files_command           - Command to list deployed files
```

## Development Workflow

For quick iterations after infrastructure is deployed:

```bash
# Make changes to Next.js app
cd nextjs-app
# Edit files...

# Quick redeploy (builds and syncs to S3)
make dev

# Check status
make status
```

## Troubleshooting

### LocalStack not responding
```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs -f

# Restart LocalStack
docker-compose restart
```

### Website not accessible
```bash
# Check if files were deployed
awslocal s3 ls s3://practical6-deployment-dev --recursive

# Verify bucket website configuration
awslocal s3api get-bucket-website --bucket practical6-deployment-dev

# Check bucket policy
awslocal s3api get-bucket-policy --bucket practical6-deployment-dev
```

### Terraform errors
```bash
# Verify LocalStack is running
curl http://localhost:4566/_localstack/health

# Check Terraform state
cd terraform
terraform show

# Refresh state
terraform refresh
```

## Security Features

The Terraform configuration includes several security best practices:

1. **Encryption**: All S3 buckets use server-side encryption (AES256)
2. **Access Logging**: Deployment bucket access is logged to a separate logs bucket
3. **Least Privilege**: Resources have minimal required permissions
4. **Public Access Control**: Explicit configuration for public website access

### Security Scanning with Trivy

This practical includes infrastructure security scanning using Trivy.

#### Scan Secure Configuration

```bash
# Scan the secure Terraform configuration
./scripts/scan.sh terraform

# Or using make
make scan
```

#### Scan Insecure Configuration

The `terraform-insecure/` directory contains intentionally vulnerable code for learning:

```bash
# Scan the insecure configuration
./scripts/scan.sh insecure

# Compare secure vs insecure
./scripts/compare-security.sh
```

#### Understanding Scan Results

Trivy reports findings by severity:

- **CRITICAL**: Immediate action required (e.g., wildcard IAM permissions)
- **HIGH**: Should be fixed soon (e.g., unencrypted S3 buckets)
- **MEDIUM**: Should be addressed (e.g., missing access logs)
- **LOW**: Nice to have (e.g., missing tags)

#### Learning Exercise

1. Run `./scripts/scan.sh all` to scan both configurations
2. Run `./scripts/compare-security.sh` to see the difference
3. Review findings in the `reports/` directory
4. Try fixing issues in `terraform-insecure/` and re-scan
5. Read `terraform-insecure/README.md` for detailed explanations

## Cleanup

### Quick cleanup (keeps data)
```bash
make clean
# or
./scripts/cleanup.sh
```

### Full cleanup (removes all data)
```bash
./scripts/cleanup.sh
# Answer 'y' to both prompts to remove LocalStack data and Terraform state
```

## Learning Objectives

This practical teaches:

1. **Infrastructure as Code**: Define cloud infrastructure using Terraform
2. **LocalStack Development**: Test AWS services locally without cloud costs
3. **Static Site Deployment**: Deploy Next.js applications to S3
4. **Security Scanning**: Use Trivy to identify IaC vulnerabilities
5. **AWS Services**: Hands-on experience with S3, IAM basics, CloudWatch Logs
6. **DevOps Workflow**: Build locally, deploy to cloud infrastructure

## Why This Approach?

This practical uses a **simplified architecture** that:
- ✅ Works with free-tier LocalStack (no Pro license required)
- ✅ Teaches core IaC concepts with Terraform
- ✅ Demonstrates S3 static website hosting
- ✅ Includes security scanning with Trivy
- ✅ Provides a foundation for more complex CI/CD pipelines

In production, you might extend this with:
- GitHub Actions or GitLab CI for automated builds
- AWS CloudFront for CDN and HTTPS
- AWS Lambda for dynamic functionality
- AWS CodePipeline for full CI/CD (requires AWS Pro or real AWS)

## Next Steps

- Modify the Next.js application and redeploy
- Add environment-specific configurations (dev, staging, prod)
- Experiment with different Terraform configurations
- Add CloudWatch alarms for monitoring
- Implement blue/green deployments with multiple S3 buckets

## Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [LocalStack Documentation](https://docs.localstack.cloud)
- [AWS S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [Next.js Static Exports](https://nextjs.org/docs/app/building-your-application/deploying/static-exports)
- [Trivy Documentation](https://trivy.dev/)
