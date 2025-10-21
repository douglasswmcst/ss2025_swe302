# Practical 6: Infrastructure as Code with Terraform and LocalStack

**YOU ARE TO CLONE PRACTICAL6-EXAMPLE REPOSITORY FROM GITHUB FOR THIS PRACTICAL.**

**Learning Outcomes:**
1. Use Terraform to define and provision infrastructure on LocalStack AWS
2. Deploy a Next.js static website to AWS S3 using Infrastructure as Code
3. Use Trivy to scan Infrastructure as Code for security vulnerabilities

**Duration:** 2-3 hours

## Overview

In this practical, you'll learn how to define, deploy, and secure cloud infrastructure using Infrastructure as Code (IaC). You'll use Terraform to provision AWS S3 buckets locally via LocalStack, deploy a Next.js static website, and scan your infrastructure code for security vulnerabilities using Trivy.

### What You'll Build

- **Infrastructure**: S3 buckets with website hosting using Terraform
- **Application**: A Next.js static website deployed to S3
- **Security**: Trivy scanning to identify and fix IaC vulnerabilities

### Technologies

- **Terraform**: Infrastructure as Code tool for defining cloud resources
- **LocalStack**: Local AWS cloud emulator (free tier)
- **AWS S3**: Object storage and static website hosting
- **Next.js**: React framework for static site generation
- **Trivy**: Security scanner for IaC and containers

## Prerequisites

Before starting, ensure you have the following tools installed:

### Required Software

1. **Docker and Docker Compose**
   - **macOS**: [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)
   - **Windows**: [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
   - **Linux**: [Docker Engine](https://docs.docker.com/engine/install/) + [Docker Compose](https://docs.docker.com/compose/install/)

2. **Terraform** (>= 1.0)
   - **macOS**: `brew install terraform`
   - **Windows**: `choco install terraform` or download from [terraform.io](https://www.terraform.io/downloads)
   - **Linux**:
     ```bash
     wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
     echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
     sudo apt update && sudo apt install terraform
     ```

3. **terraform-local (tflocal)** - Wrapper for Terraform with LocalStack
   - **All platforms**:
     ```bash
     pip install terraform-local
     ```
   - **What it does**: `tflocal` is a thin wrapper that automatically configures Terraform to use LocalStack endpoints
   - **Why you need it**: Simplifies Terraform commands by auto-configuring LocalStack settings
   - **Usage**: Use `tflocal` instead of `terraform` (e.g., `tflocal init`, `tflocal apply`)

4. **Node.js** (>= 18)
   - **macOS**: `brew install node`
   - **Windows**: Download from [nodejs.org](https://nodejs.org/) or `choco install nodejs`
   - **Linux**:
     ```bash
     curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
     sudo apt-get install -y nodejs
     ```

5. **AWS CLI** with `awslocal` wrapper
   - **All platforms**:
     ```bash
     pip install awscli awscli-local
     ```

6. **Trivy** (Security Scanner)
   - **macOS**: `brew install trivy`
   - **Windows**:
     ```powershell
     # Using Chocolatey
     choco install trivy

     # Or download binary from GitHub
     # https://github.com/aquasecurity/trivy/releases
     ```
   - **Linux**:
     ```bash
     # Debian/Ubuntu
     sudo apt-get install wget apt-transport-https gnupg lsb-release
     wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
     echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
     sudo apt-get update
     sudo apt-get install trivy

     # RHEL/CentOS
     sudo rpm -ivh https://github.com/aquasecurity/trivy/releases/download/v0.48.0/trivy_0.48.0_Linux-64bit.rpm
     ```

7. **Code Editor**
   - [Visual Studio Code](https://code.visualstudio.com/) (recommended)
   - Or any text editor of your choice

### Knowledge Prerequisites

- Basic understanding of Git and version control
- Familiarity with AWS concepts (S3, IAM)
- Comfortable using command line/terminal
- Basic knowledge of web development

### Verify Installation

After installing all tools, verify they're working:

```bash
# Check Docker
docker --version
docker-compose --version

# Check Terraform and tflocal
terraform --version
tflocal --version  # Should show same version as terraform

# Check Node.js
node --version
npm --version

# Check AWS CLI and awslocal
aws --version
awslocal --version  # LocalStack wrapper for AWS CLI

# Check Trivy
trivy --version
```

All commands should return version numbers without errors.

**Note**: `tflocal` and `awslocal` are wrapper scripts that should show the same underlying version as `terraform` and `aws` respectively. If `tflocal --version` shows the same Terraform version, it's correctly installed.

## Part 1: Understanding the Architecture

### Deployment Flow

```
Developer Machine                    LocalStack AWS
       │                                   │
       │  1. Write Terraform         ┌─────▼──────┐
       │     Define S3 buckets       │ Terraform  │
       │                             │   Apply    │
       │                             └─────┬──────┘
       │                                   │
       │                             ┌─────▼──────────┐
       │                             │  S3 Buckets    │
       │                             │  - Deployment  │
       │                             │  - Logs        │
       │                             └─────┬──────────┘
       │                                   │
       │  2. Build Next.js                 │
       │     npm run build                 │
       │     (creates /out)                │
       │                                   │
       │  3. Deploy to S3            ┌─────▼──────────┐
       │     awslocal s3 sync  ─────>│  S3 Deployment │
       │                             │  (Website)     │
       │                             └─────┬──────────┘
       │                                   │
       │  4. Access Website          ┌─────▼──────────┐
       │     <──────────────────────>│  Public Access │
       │                             │  http://...    │
       │                             └────────────────┘
```

### Infrastructure Components

1. **S3 Deployment Bucket**
   - Hosts static website files
   - Configured with website hosting enabled
   - Public read access for website visitors
   - Server-side encryption (AES256)

2. **S3 Logs Bucket**
   - Stores access logs for the deployment bucket
   - Enables audit trail of website access
   - Encrypted at rest

3. **Bucket Policies**
   - Public read policy for website content
   - Explicit permissions configuration

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
│   └── package.json           # Node.js dependencies
│
├── terraform/                 # Secure infrastructure code
│   ├── main.tf                # Provider configuration
│   ├── variables.tf           # Input variables
│   ├── s3.tf                  # S3 bucket resources
│   ├── iam.tf                 # IAM examples (educational)
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

# View the website
curl $(cd terraform && terraform output -raw deployment_website_endpoint)
```

### Option B: Manual Step-by-Step

Follow this approach to understand each step:

```bash
# 1. Start LocalStack
./scripts/setup.sh
OR
localstack start

# 2. Install Next.js dependencies
cd nextjs-app
npm ci
cd ..

OR

# 2a. Setup Next.js app yourself with 
npx create-next-app nextjs-app
cd nextjs-app
npm install
cd ..

# 3. Initialize Terraform
cd terraform
tflocal init
cd ..

# 4. Build Next.js application
cd nextjs-app
npm run build
cd ..

# 5. Deploy infrastructure
cd terraform
tflocal plan
tflocal apply
cd ..

# 6. Deploy application to S3
awslocal s3 sync nextjs-app/out/ s3://$(cd terraform && terraform output -raw deployment_bucket_name)/ --delete

# 7. Check deployment
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
resource "aws_s3_bucket_server_side_encryption_configuration" "deployment" {
  bucket = aws_s3_bucket.deployment.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Website hosting configured
resource "aws_s3_bucket_website_configuration" "deployment" {
  bucket = aws_s3_bucket.deployment.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

# Access logging
resource "aws_s3_bucket_logging" "deployment" {
  bucket = aws_s3_bucket.deployment.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "deployment-logs/"
}
```

**Questions to Consider:**
1. Why is encryption important for S3 buckets?
2. What happens if someone tries to access a page that doesn't exist?
3. How does access logging help with security and compliance?

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
- Encrypted buckets, access logging enabled

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
HIGH: Bucket does not have encryption enabled
────────────────────────────────────────────────────────────────
  ID: AVD-AWS-0088
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

**Steps**:
```bash
# Edit the file
code nextjs-app/app/page.tsx

# Redeploy
make dev

# View changes
curl $(cd terraform && terraform output -raw deployment_website_endpoint)
```

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

### Exercise 3: Add a New S3 Bucket

**Task**: Create a new S3 bucket for backups

1. Open `terraform/s3.tf`
2. Add a new bucket resource:
   ```hcl
   resource "aws_s3_bucket" "backups" {
     bucket = "${var.project_name}-backups-${var.environment}"

     tags = {
       Name        = "Backups Bucket"
       Environment = var.environment
       Project     = var.project_name
     }
   }
   ```
3. Add encryption for the backup bucket
4. Run `tflocal plan` to preview changes
5. Apply with `tflocal apply`
6. Verify with:
   ```bash
   awslocal s3 ls | grep backups
   ```

### Exercise 4: Implement Versioning

**Task**: Add versioning to the deployment bucket

1. Open `terraform/s3.tf`
2. Add versioning configuration:
   ```hcl
   resource "aws_s3_bucket_versioning" "deployment" {
     bucket = aws_s3_bucket.deployment.id

     versioning_configuration {
       status = "Enabled"
     }
   }
   ```
3. Apply changes: `tflocal apply`
4. Verify with:
   ```bash
   awslocal s3api get-bucket-versioning --bucket practical6-deployment-dev
   ```

**Benefits of Versioning:**
- Recover from accidental deletions
- Maintain file history
- Rollback to previous versions

### Exercise 5: Monitor Website Access

**Task**: View access logs from your website

1. Deploy the website and access it a few times:
   ```bash
   curl $(cd terraform && terraform output -raw deployment_website_endpoint)
   ```
2. Check the logs bucket:
   ```bash
   awslocal s3 ls s3://practical6-logs-dev/deployment-logs/
   ```
3. Download and view a log file:
   ```bash
   awslocal s3 cp s3://practical6-logs-dev/deployment-logs/[log-file] ./access.log
   cat access.log
   ```

**What to Look For:**
- Timestamp of access
- IP address (simulated in LocalStack)
- HTTP method and path
- HTTP status code

## Part 7: Monitoring and Troubleshooting

### Checking Deployment Status

```bash
# Overall status
./scripts/status.sh

# List deployed files
awslocal s3 ls s3://practical6-deployment-dev --recursive

# Check bucket configuration
awslocal s3api get-bucket-website --bucket practical6-deployment-dev
```

### Common Issues and Solutions

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

# Verify index.html exists
awslocal s3 ls s3://practical6-deployment-dev/index.html
```

#### Issue: Terraform apply fails

**Symptom**: Error during `tflocal apply`

**Solution**:
```bash
# Verify LocalStack is running
curl http://localhost:4566/_localstack/health

# Check LocalStack logs
docker-compose logs -f localstack

# Destroy and recreate
tflocal destroy
tflocal apply
```

#### Issue: Build fails

**Symptom**: `npm run build` fails

**Solution**:
```bash
# Clean and reinstall dependencies
cd nextjs-app
rm -rf node_modules .next
npm ci
npm run build
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
- [ ] Write Terraform configurations for AWS S3 buckets
- [ ] Use LocalStack to test AWS infrastructure locally
- [ ] Deploy static websites to S3
- [ ] Scan IaC for security vulnerabilities using Trivy
- [ ] Identify and fix common security misconfigurations
- [ ] Implement security best practices (encryption, logging)
- [ ] Understand the difference between secure and insecure configurations
- [ ] Navigate and troubleshoot infrastructure deployments

## Part 9: Understanding IaC Benefits

### Why Infrastructure as Code?

**Traditional Approach (Manual):**
- Click through AWS console
- Hard to reproduce
- No version control
- Difficult to collaborate
- Error-prone

**IaC Approach (Terraform):**
- Define infrastructure in code
- Version controlled (Git)
- Reproducible deployments
- Easy collaboration
- Automated and consistent

### Terraform Workflow

```
Write → Plan → Apply → Manage
  ↓       ↓       ↓        ↓
Code   Preview  Deploy  Update
```

1. **Write**: Define resources in `.tf` files
2. **Plan**: Preview changes before applying
3. **Apply**: Create/update infrastructure
4. **Manage**: Track state, make updates

## Further Reading

### Infrastructure as Code
- [Terraform Documentation](https://www.terraform.io/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### LocalStack
- [LocalStack Documentation](https://docs.localstack.cloud)
- [LocalStack AWS Feature Coverage](https://docs.localstack.cloud/references/coverage/)
- [LocalStack GitHub](https://github.com/localstack/localstack)

### AWS S3
- [S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)

### Security
- [Trivy Documentation](https://trivy.dev/)
- [AWS Security Best Practices](https://docs.aws.amazon.com/security/)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [OWASP IaC Security](https://cheatsheetseries.owasp.org/cheatsheets/Infrastructure_as_Code_Security_Cheat_Sheet.html)

### Next.js
- [Next.js Documentation](https://nextjs.org/docs)
- [Static Exports](https://nextjs.org/docs/app/building-your-application/deploying/static-exports)


## Submission Requiremnts

1. Main Outcome 
 - Remove all critical and high vulnerabilities from the insecure terraform code using trivy as a guide.
 - 
Document your work by:

1. Taking screenshots of:
   - Successful Terraform apply
   - Deployed website
   - Trivy scan results (both secure and insecure) displaying zero critical and high vulnerabilities
   - Fixed security issue

2. Answering these reflection questions:
   - Why is it important to scan IaC for security issues?
   - How does LocalStack help in the development workflow?

3. Share your implementation:
   - Git repository with your changes

## Conclusion

You've now experienced the fundamentals of Infrastructure as Code:
- Defining infrastructure declaratively with Terraform
- Deploying to a local AWS environment with LocalStack
- Hosting static websites on S3
- Ensuring security with Trivy scanning

These skills are essential for modern DevOps and cloud engineering roles. The principles you've learned apply not just to AWS, but to any cloud provider and IaC tool.

**Key Takeaways:**
- IaC makes infrastructure reproducible and version-controlled
- Security should be built into infrastructure from the start
- Automated scanning catches issues before they reach production
- LocalStack enables local development without cloud costs
- Terraform provides a consistent way to manage cloud resources

Keep practicing, and remember: **Security should be part of your workflow from day one, not an afterthought!**
