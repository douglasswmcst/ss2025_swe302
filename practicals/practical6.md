# Practical 6: Infrastructure as Code with Terraform and LocalStack

**Learning Outcomes:**
1. Use Terraform to define infrastructure on LocalStack AWS
2. Deploy a basic Next.js starter kit to LocalStack AWS using AWS CodePipeline
3. Use Trivy to test Infrastructure as Code security

**Duration:** 2-3 hours

## Overview

In this practical, you'll learn how to define, deploy, and secure cloud infrastructure using Infrastructure as Code (IaC). You'll use Terraform to provision AWS services locally via LocalStack, build a CI/CD pipeline with AWS CodePipeline, and scan your infrastructure code for security vulnerabilities using Trivy.

### What You'll Build

- **Infrastructure**: S3 buckets, IAM roles, CodePipeline, and CodeBuild using Terraform
- **Application**: A Next.js static website deployed via automated pipeline
- **Security**: Trivy scanning to identify and fix IaC vulnerabilities

### Technologies

- **Terraform**: Infrastructure as Code tool
- **LocalStack**: Local AWS cloud emulator
- **AWS CodePipeline**: CI/CD orchestration service
- **AWS CodeBuild**: Build service for compiling and testing code
- **Next.js**: React framework for static site generation
- **Trivy**: Security scanner for IaC and containers

## Prerequisites

Before starting, ensure you have:

- Docker and Docker Compose installed
- Terraform >= 1.0 (`brew install terraform`)
- Node.js >= 18 (`brew install node`)
- AWS CLI with `awslocal` wrapper (`pip install awscli-local`)
- Trivy (`brew install trivy`)
- A code editor (VS Code recommended)
- Basic understanding of Git, AWS concepts, and terminal usage

## Part 1: Understanding the Architecture

### CI/CD Pipeline Flow

```
Developer                 LocalStack AWS
   │                           │
   │  1. Build Next.js         │
   │     npm run build         │
   │                           │
   │  2. Create ZIP            │
   │     nextjs-app.zip        │
   │                           │
   │  3. Upload to S3     ────>│  S3 Source Bucket
   │                           │         │
   │                           │         │ triggers
   │                           │         v
   │                           │   CodePipeline
   │                           │    ┌──────────┐
   │                           │    │  Source  │
   │                           │    └────┬─────┘
   │                           │         │
   │                           │         v
   │                           │    ┌──────────┐
   │                           │    │  Build   │──> CodeBuild
   │                           │    └────┬─────┘   (npm install,
   │                           │         │          npm run build)
   │                           │         v
   │                           │    ┌──────────┐
   │                           │    │  Deploy  │
   │                           │    └────┬─────┘
   │                           │         │
   │                           │         v
   │                           │  S3 Deployment Bucket
   │                           │  (Static Website)
   │                           │
   │  4. Access Website   <────│  http://bucket.s3-website...
   │                           │
```

### Infrastructure Components

1. **S3 Buckets**
   - **Source**: Stores application ZIP files
   - **Artifacts**: Stores pipeline intermediate artifacts
   - **Deployment**: Hosts the static website
   - **Logs**: Stores access logs for audit

2. **IAM Roles**
   - **CodePipeline Role**: Permissions to orchestrate pipeline stages
   - **CodeBuild Role**: Permissions to build and access S3

3. **CodeBuild Project**
   - Uses `buildspec.yml` to define build steps
   - Installs dependencies, runs linting, builds Next.js app
   - Outputs static files for deployment

4. **CodePipeline**
   - **Stage 1 - Source**: Detects new uploads to S3
   - **Stage 2 - Build**: Runs CodeBuild project
   - **Stage 3 - Deploy**: Copies build artifacts to deployment bucket

## Part 2: Exploring the Project Structure

Navigate to the practical6-example directory:

```bash
cd practicals/practical6-example
```

### Key Directories

```
practical6-example/
├── docker-compose.yml          # LocalStack configuration
├── Makefile                    # Convenience commands
├── trivy.yaml                  # Trivy scanner configuration
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
│   ├── app/                   # Next.js application code
│   ├── next.config.js         # Configured for static export
│   ├── buildspec.yml          # CodeBuild build specification
│   └── package.json           # Node.js dependencies
│
├── terraform/                 # Secure infrastructure code
│   ├── main.tf                # Provider configuration
│   ├── variables.tf           # Input variables
│   ├── s3.tf                  # S3 bucket resources
│   ├── iam.tf                 # IAM roles and policies
│   ├── codebuild.tf           # CodeBuild project
│   ├── codepipeline.tf        # Pipeline definition
│   └── outputs.tf             # Output values
│
└── terraform-insecure/        # Intentionally vulnerable code (for learning)
    ├── s3-insecure.tf         # Insecure S3 configurations
    ├── iam-insecure.tf        # Insecure IAM configurations
    └── README.md              # Explanation of vulnerabilities
```

## Part 3: Quick Start Deployment

### Option A: Automated Deployment (Recommended for First Run)

```bash
# Initialize dependencies
make init

# Deploy everything (LocalStack + Terraform + Application)
make deploy

# Check status
make status

# View the website (in browser or with curl)
curl $(cd terraform && terraform output -raw deployment_website_endpoint)
```

### Option B: Manual Step-by-Step

Follow this approach to understand each step:

```bash
# 1. Start LocalStack
./scripts/setup.sh

# 2. Install Next.js dependencies
cd nextjs-app
npm ci
cd ..

# 3. Initialize Terraform
cd terraform
terraform init
cd ..

# 4. Build Next.js application
cd nextjs-app
npm run build
cd ..

# 5. Package the application
cd nextjs-app/out
zip -r ../../nextjs-app.zip .
cd ../..

# 6. Deploy infrastructure
cd terraform
terraform plan
terraform apply
cd ..

# 7. Upload source code
awslocal s3 cp nextjs-app.zip s3://$(cd terraform && terraform output -raw source_bucket_name)/nextjs-app.zip

# 8. Trigger pipeline
awslocal codepipeline start-pipeline-execution --name $(cd terraform && terraform output -raw pipeline_name)

# 9. Monitor progress
./scripts/status.sh
```

## Part 4: Understanding Terraform Configuration

### Examining main.tf

Open `terraform/main.tf`:

```hcl
provider "aws" {
  region = "us-east-1"

  # LocalStack-specific configuration
  access_key = "test"
  secret_key = "test"
  skip_credentials_validation = true
  skip_metadata_api_check = true
  skip_requesting_account_id = true
  s3_use_path_style = true

  # LocalStack endpoints
  endpoints {
    s3 = "http://localhost:4566"
    iam = "http://localhost:4566"
    codepipeline = "http://localhost:4566"
    codebuild = "http://localhost:4566"
    sts = "http://localhost:4566"
    logs = "http://localhost:4566"
  }
}
```

**Key Points:**
- The `endpoints` block redirects AWS API calls to LocalStack
- `s3_use_path_style = true` is required for LocalStack S3 compatibility
- Test credentials are safe because they're only for local development

### Examining s3.tf

Open `terraform/s3.tf` and note the security features:

```hcl
# Encryption enabled
resource "aws_s3_bucket_server_side_encryption_configuration" "source" {
  bucket = aws_s3_bucket.source.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Versioning enabled
resource "aws_s3_bucket_versioning" "source" {
  bucket = aws_s3_bucket.source.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Access logging
resource "aws_s3_bucket_logging" "deployment" {
  bucket = aws_s3_bucket.deployment.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "deployment-logs/"
}
```

### Examining iam.tf

Open `terraform/iam.tf` and observe the least-privilege policies:

```hcl
# Specific actions (not wildcards)
Action = [
  "s3:GetObject",
  "s3:GetObjectVersion",
  "s3:PutObject"
]

# Specific resources (not wildcards)
Resource = [
  aws_s3_bucket.source.arn,
  "${aws_s3_bucket.source.arn}/*"
]
```

**Questions to Consider:**
1. Why are specific actions better than `s3:*`?
2. What could go wrong with `Resource = "*"`?
3. How does this follow the principle of least privilege?

## Part 5: Security Scanning with Trivy

### Scanning Secure Configuration

Run Trivy on your secure Terraform code:

```bash
./scripts/scan.sh terraform
# or
make scan
```

**Expected Results:**
- Few or no HIGH/CRITICAL findings
- Some MEDIUM/LOW findings (acceptable in many contexts)
- Encrypted buckets, specific IAM permissions, access logging

### Scanning Insecure Configuration

Now scan the intentionally vulnerable code:

```bash
./scripts/scan.sh insecure
# or
make scan-insecure
```

**Expected Results:**
- Multiple CRITICAL findings (wildcard IAM permissions)
- Multiple HIGH findings (unencrypted buckets, public write access)
- Missing security features throughout

### Comparing Configurations

Run the comparison script:

```bash
./scripts/compare-security.sh
# or
make compare-security
```

**Analysis Questions:**
1. How many more issues does the insecure configuration have?
2. What percentage reduction in vulnerabilities did security best practices achieve?
3. Which findings are most critical to fix?

### Understanding Trivy Findings

Trivy reports vulnerabilities by:

- **AVD ID**: AWS Vulnerability Database identifier (e.g., AVD-AWS-0132)
- **Severity**: CRITICAL, HIGH, MEDIUM, LOW
- **Resource**: Which Terraform resource has the issue
- **Description**: What's wrong and why it matters
- **Recommendation**: How to fix it

Example finding:

```
CRITICAL: Bucket does not encrypt data with a customer managed key
────────────────────────────────────────────────────────────────
  ID: AVD-AWS-0132
  Resource: aws_s3_bucket.insecure_example
  Line: 5
  Recommendation: Enable server-side encryption with AES256 or KMS
```

## Part 6: Exercises

### Exercise 1: Modify the Next.js Application

**Task**: Update the landing page and redeploy

1. Edit `nextjs-app/app/page.tsx`
2. Change the title or add a new component
3. Redeploy using `make dev`
4. Verify changes by accessing the website

**Expected Outcome**: Your changes should appear on the deployed site

### Exercise 2: Fix a Security Issue

**Task**: Fix one vulnerability in `terraform-insecure/`

1. Choose a finding from the Trivy scan
2. Read the recommendation
3. Apply the fix to the insecure Terraform file
4. Re-scan to verify: `./scripts/scan.sh insecure`

**Example Fix**:
```hcl
# Before (insecure)
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"
}

# After (secure)
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

### Exercise 3: Add a Pipeline Stage

**Task**: Add a testing stage to the CodePipeline

1. Create a test script in `nextjs-app/` (e.g., `npm test`)
2. Update `nextjs-app/buildspec.yml` to include a test phase
3. Modify `terraform/codepipeline.tf` to add a test stage
4. Apply changes: `terraform apply`
5. Trigger pipeline and verify tests run

**Hint**: Look at the existing Build stage as a template

### Exercise 4: Monitor Pipeline Execution

**Task**: Observe and understand pipeline behavior

1. Trigger a new pipeline execution:
   ```bash
   awslocal codepipeline start-pipeline-execution --name practical6-pipeline
   ```
2. Watch the pipeline progress:
   ```bash
   ./scripts/status.sh
   ```
3. View CodeBuild logs in real-time:
   ```bash
   make logs
   ```

**Questions**:
- How long does each stage take?
- What happens if a build fails?
- Where are build artifacts stored?

### Exercise 5: Implement a Security Fix

**Task**: Add versioning to the artifacts bucket

1. Open `terraform/s3.tf`
2. Add versioning to the artifacts bucket (similar to source bucket)
3. Run `terraform plan` to preview changes
4. Apply with `terraform apply`
5. Verify with:
   ```bash
   awslocal s3api get-bucket-versioning --bucket practical6-artifacts-dev
   ```

## Part 7: Monitoring and Troubleshooting

### Checking Pipeline Status

```bash
# Overall status
./scripts/status.sh

# Detailed pipeline state
awslocal codepipeline get-pipeline-state --name practical6-pipeline

# List recent executions
awslocal codepipeline list-pipeline-executions --pipeline-name practical6-pipeline
```

### Viewing Build Logs

```bash
# Tail logs in real-time
make logs

# Or manually
awslocal logs tail /aws/codebuild/practical6-build --follow

# List all log streams
awslocal logs describe-log-streams --log-group-name /aws/codebuild/practical6-build
```

### Common Issues and Solutions

#### Issue: Pipeline not triggering

**Symptom**: After uploading to S3, pipeline doesn't start

**Solution**:
```bash
# Manually trigger pipeline
awslocal codepipeline start-pipeline-execution --name practical6-pipeline

# Check if source changed
awslocal s3api head-object --bucket practical6-source-dev --key nextjs-app.zip
```

#### Issue: Build fails

**Symptom**: Build stage shows failed status

**Solution**:
```bash
# View build logs
make logs

# Check CodeBuild project configuration
awslocal codebuild batch-get-projects --names practical6-build

# Verify buildspec.yml syntax
cat nextjs-app/buildspec.yml
```

#### Issue: Website not accessible

**Symptom**: 403 or 404 error when accessing website

**Solution**:
```bash
# Check if files were deployed
awslocal s3 ls s3://practical6-deployment-dev --recursive

# Verify bucket policy allows public read
awslocal s3api get-bucket-policy --bucket practical6-deployment-dev

# Check website configuration
awslocal s3api get-bucket-website --bucket practical6-deployment-dev
```

## Part 8: Clean Up

When you're done:

```bash
# Full cleanup
make clean

# Or manually
./scripts/cleanup.sh
```

This will:
1. Destroy Terraform infrastructure
2. Stop LocalStack container
3. Remove generated files
4. Optionally delete persisted data

## Learning Checkpoints

By completing this practical, you should be able to:

- [ ] Explain what Infrastructure as Code (IaC) is and its benefits
- [ ] Write Terraform configurations for AWS services
- [ ] Use LocalStack to test AWS infrastructure locally
- [ ] Create and manage an AWS CodePipeline
- [ ] Configure CodeBuild to build and test applications
- [ ] Deploy static websites to S3
- [ ] Scan IaC for security vulnerabilities using Trivy
- [ ] Identify and fix common security misconfigurations
- [ ] Apply the principle of least privilege to IAM policies
- [ ] Implement security best practices (encryption, logging, versioning)
- [ ] Monitor and troubleshoot CI/CD pipelines

## Further Reading

### Infrastructure as Code
- [Terraform Documentation](https://www.terraform.io/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### LocalStack
- [LocalStack Documentation](https://docs.localstack.cloud)
- [LocalStack AWS Feature Coverage](https://docs.localstack.cloud/references/coverage/)
- [LocalStack GitHub](https://github.com/localstack/localstack)

### AWS CI/CD
- [AWS CodePipeline User Guide](https://docs.aws.amazon.com/codepipeline/latest/userguide/)
- [AWS CodeBuild User Guide](https://docs.aws.amazon.com/codebuild/latest/userguide/)
- [Buildspec Reference](https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html)

### Security
- [Trivy Documentation](https://trivy.dev/)
- [AWS Security Best Practices](https://docs.aws.amazon.com/security/)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [OWASP IaC Security](https://cheatsheetseries.owasp.org/cheatsheets/Infrastructure_as_Code_Security_Cheat_Sheet.html)

### Next.js
- [Next.js Documentation](https://nextjs.org/docs)
- [Static Exports](https://nextjs.org/docs/app/building-your-application/deploying/static-exports)

## Challenge: Advanced Topics

If you finish early, try these advanced challenges:

1. **Multi-Environment Setup**: Modify Terraform to support dev/staging/prod environments
2. **Custom Domain**: Configure a custom domain for the S3 website (using LocalStack)
3. **CloudFront Distribution**: Add a CloudFront distribution in front of S3
4. **Automated Testing**: Add integration tests that run in the pipeline
5. **Terraform Modules**: Refactor code into reusable Terraform modules
6. **State Management**: Configure remote state storage (S3 backend)
7. **Blue/Green Deployment**: Implement zero-downtime deployments
8. **Monitoring**: Add CloudWatch alarms and dashboards
9. **Cost Analysis**: Add cost estimation with Infracost
10. **GitOps Workflow**: Integrate with GitHub Actions for automated deployments

## Submission

Document your work by:

1. Taking screenshots of:
   - Successful pipeline execution
   - Deployed website
   - Trivy scan results (both secure and insecure)
   - Fixed security issue

2. Answering these reflection questions:
   - What are the main benefits of Infrastructure as Code?
   - Why is it important to scan IaC for security issues?
   - How does LocalStack help in the development workflow?
   - What did you learn about AWS CodePipeline?

3. (Optional) Share your implementation:
   - Git repository with your changes
   - Any additional features you implemented

## Conclusion

You've now experienced the full lifecycle of Infrastructure as Code:
- Defining infrastructure declaratively with Terraform
- Deploying to a local AWS environment with LocalStack
- Building automated CI/CD pipelines with CodePipeline
- Ensuring security with Trivy scanning

These skills are essential for modern DevOps and cloud engineering roles. The principles you've learned apply not just to AWS, but to any cloud provider and IaC tool.

Keep practicing, and remember: **Security should be part of your workflow from day one, not an afterthought!**
