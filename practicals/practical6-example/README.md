# Practical 6 - Infrastructure as Code with Terraform

This example demonstrates deploying a Next.js application to LocalStack AWS using Terraform and AWS CodePipeline.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         LocalStack                           │
│                                                               │
│  ┌──────────┐      ┌─────────────────────────────────┐      │
│  │ S3       │      │     AWS CodePipeline            │      │
│  │ Source   │─────>│                                 │      │
│  │ Bucket   │      │  ┌──────┐  ┌──────┐  ┌──────┐  │      │
│  └──────────┘      │  │Source│─>│Build │─>│Deploy│  │      │
│                    │  └──────┘  └──────┘  └──────┘  │      │
│                    │               │                 │      │
│                    │               v                 │      │
│                    │         ┌──────────┐            │      │
│                    │         │CodeBuild │            │      │
│                    │         └──────────┘            │      │
│                    └──────────────┬──────────────────┘      │
│                                   │                          │
│                                   v                          │
│                         ┌────────────────┐                   │
│                         │  S3 Deployment │                   │
│                         │  (Static Site) │                   │
│                         └────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

## Components

### Infrastructure (Terraform)
- **S3 Buckets**: Source code, pipeline artifacts, deployment, and logs
- **IAM Roles**: CodePipeline and CodeBuild service roles with least-privilege policies
- **CodeBuild**: Builds Next.js application using `buildspec.yml`
- **CodePipeline**: Orchestrates Source → Build → Deploy workflow

### Application
- **Next.js 14**: Modern React framework configured for static export
- **Static Site**: Deployed to S3 with website hosting enabled

## Prerequisites

- Docker and Docker Compose
- Terraform >= 1.0
- Node.js >= 18
- AWS CLI with `awslocal` wrapper (via `pip install awscli-local`)
- Trivy (for security scanning: `brew install trivy` on macOS)
- Make (optional, for convenience commands)

## Quick Start

### Option 1: Using Make (Recommended)

```bash
# Initialize dependencies
make init

# Deploy everything
make deploy

# Check status
make status

# View logs
make logs

# Clean up
make clean
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
- CodePipeline
- CodeBuild
- CloudWatch Logs
- STS

### 2. Build Next.js Application

```bash
cd nextjs-app
npm ci
npm run build
```

The build creates a static export in the `out/` directory.

### 3. Package Application

```bash
cd nextjs-app/out
zip -r ../../nextjs-app.zip .
```

### 4. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This creates:
- 4 S3 buckets (source, artifacts, deployment, logs)
- IAM roles and policies
- CodeBuild project
- CodePipeline with 3 stages

### 5. Upload Source Code

```bash
# Get bucket name from Terraform outputs
SOURCE_BUCKET=$(cd terraform && terraform output -raw source_bucket_name)

# Upload ZIP file
awslocal s3 cp nextjs-app.zip s3://$SOURCE_BUCKET/nextjs-app.zip
```

### 6. Trigger Pipeline

```bash
# Get pipeline name
PIPELINE_NAME=$(cd terraform && terraform output -raw pipeline_name)

# Start execution
awslocal codepipeline start-pipeline-execution --name $PIPELINE_NAME
```

### 7. Monitor Progress

```bash
# Check pipeline status
./scripts/status.sh

# View build logs
awslocal logs tail /aws/codebuild/practical6-build --follow
```

### 8. Access Website

```bash
# Get website endpoint
WEBSITE=$(cd terraform && terraform output -raw deployment_website_endpoint)

# Open in browser or curl
curl $WEBSITE
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
│   └── cleanup.sh             # Clean up everything
│
├── nextjs-app/
│   ├── app/                   # Next.js application
│   ├── next.config.js         # Configured for static export
│   ├── buildspec.yml          # CodeBuild build specification
│   └── package.json
│
└── terraform/
    ├── main.tf                # Provider and backend configuration
    ├── variables.tf           # Input variables
    ├── s3.tf                  # S3 bucket definitions
    ├── iam.tf                 # IAM roles and policies
    ├── codebuild.tf           # CodeBuild project
    ├── codepipeline.tf        # CodePipeline definition
    └── outputs.tf             # Output values
```

## Terraform Outputs

After applying Terraform, you'll see these useful outputs:

```
source_bucket_name           - Name of the source S3 bucket
artifacts_bucket_name        - Name of the artifacts S3 bucket
deployment_bucket_name       - Name of the deployment S3 bucket
deployment_website_endpoint  - Website URL
pipeline_name                - CodePipeline name
codebuild_project_name       - CodeBuild project name
upload_command               - Command to upload source code
trigger_pipeline_command     - Command to trigger pipeline
```

## Development Workflow

For quick iterations:

```bash
# Make changes to Next.js app
cd nextjs-app
# Edit files...

# Quick redeploy (skips Terraform if no infrastructure changes)
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

### Pipeline fails
```bash
# Check pipeline state
awslocal codepipeline get-pipeline-state --name practical6-pipeline

# View build logs
awslocal logs tail /aws/codebuild/practical6-build --follow

# Check build details
awslocal codebuild list-builds-for-project --project-name practical6-build
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
3. **Least Privilege**: IAM roles have minimal required permissions
4. **Versioning**: Source bucket has versioning enabled (required by CodePipeline)

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

#### Common Vulnerabilities Detected

1. **Unencrypted Storage**: S3 buckets without server-side encryption
2. **Overly Permissive IAM**: Wildcard actions or resources in policies
3. **Missing Logging**: No audit trail for access
4. **Public Access**: Buckets publicly accessible when not needed
5. **No Versioning**: Missing data recovery capabilities

#### Integration with CI/CD

Add Trivy scanning to your pipeline:

```yaml
# Example CodeBuild phase
- name: security_scan
  commands:
    - trivy config --severity CRITICAL,HIGH --exit-code 1 terraform/
```

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
2. **CI/CD Pipelines**: Build automated deployment pipelines with CodePipeline
3. **LocalStack Development**: Test AWS services locally without cloud costs
4. **Static Site Deployment**: Deploy Next.js applications as static sites
5. **AWS Services**: Hands-on experience with S3, IAM, CodePipeline, CodeBuild

## Next Steps

- Modify the Next.js application and redeploy
- Add additional pipeline stages (e.g., testing)
- Experiment with different Terraform configurations
- Add CloudWatch alarms for monitoring
- Implement blue/green deployments

## Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [LocalStack Documentation](https://docs.localstack.cloud)
- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/)
- [Next.js Static Exports](https://nextjs.org/docs/app/building-your-application/deploying/static-exports)
