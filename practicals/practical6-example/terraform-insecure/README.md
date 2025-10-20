# Insecure Terraform Configuration (Educational)

**WARNING: This directory contains intentionally vulnerable Infrastructure as Code (IaC) for educational purposes only. NEVER use these configurations in production!**

## Purpose

This directory demonstrates common security misconfigurations in Terraform code. It's designed to help you:

1. Learn to identify security issues in IaC
2. Understand the importance of security scanning
3. See the difference between secure and insecure configurations
4. Practice using Trivy to detect vulnerabilities

## Security Issues Demonstrated

### S3 Bucket Misconfigurations (`s3-insecure.tf`)

1. **No Encryption**: Buckets don't use server-side encryption
2. **No Versioning**: Missing version control for data recovery
3. **No Access Logging**: Can't audit who accessed what
4. **Public Access Allowed**: Buckets are publicly accessible
5. **Overly Permissive Policies**: Anyone can read, write, and delete objects
6. **No Lifecycle Policies**: No cost management for old data
7. **No MFA Delete**: No additional protection for deletions

### IAM Misconfigurations (`iam-insecure.tf`)

1. **Wildcard Actions**: Policies use `*` for actions (e.g., `s3:*`, `iam:*`)
2. **Wildcard Resources**: Policies apply to all resources (`Resource: "*"`)
3. **Admin Access**: Users/roles have unnecessary administrator permissions
4. **No MFA Enforcement**: No multi-factor authentication required
5. **Hardcoded Credentials**: Access keys created without proper rotation
6. **No Password Policies**: Weak password requirements
7. **Excessive Permissions**: Violates least privilege principle

## Scanning for Vulnerabilities

### Quick Scan

```bash
# Scan the insecure configuration
./scripts/scan.sh insecure

# Compare with secure configuration
./scripts/compare-security.sh
```

### Expected Findings

When you scan this directory with Trivy, you should see:

- **CRITICAL** findings for wildcard IAM permissions
- **HIGH** findings for unencrypted S3 buckets
- **MEDIUM** findings for missing logging and versioning
- **LOW** findings for missing tags and lifecycle policies

## Learning Exercise

### Step 1: Scan the Insecure Configuration

```bash
./scripts/scan.sh insecure
```

Review the findings and understand what each vulnerability means.

### Step 2: Compare with Secure Configuration

```bash
./scripts/compare-security.sh
```

See how the secure configuration in `terraform/` addresses these issues.

### Step 3: Identify Fixes

For each finding, determine how the secure configuration fixes it:

| Issue | Insecure | Secure |
|-------|----------|--------|
| S3 Encryption | Not configured | `sse_algorithm = "AES256"` |
| S3 Logging | Not configured | Dedicated logs bucket with `aws_s3_bucket_logging` |
| IAM Wildcards | `Action: "s3:*"` | Specific actions like `s3:GetObject` |
| Public Access | Allowed | Restricted with proper policies |

### Step 4: Fix One Issue

Try fixing one security issue in this directory and re-scan to verify the fix.

## Common Vulnerabilities and Fixes

### 1. Unencrypted S3 Buckets

**Vulnerable:**
```hcl
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"
}
```

**Fixed:**
```hcl
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

### 2. Overly Permissive IAM Policies

**Vulnerable:**
```hcl
policy = jsonencode({
  Statement = [{
    Effect   = "Allow"
    Action   = "s3:*"
    Resource = "*"
  }]
})
```

**Fixed:**
```hcl
policy = jsonencode({
  Statement = [{
    Effect = "Allow"
    Action = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    Resource = "arn:aws:s3:::specific-bucket/*"
  }]
})
```

### 3. Public S3 Bucket Access

**Vulnerable:**
```hcl
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
```

**Fixed (for private buckets):**
```hcl
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

## Security Best Practices

1. **Principle of Least Privilege**: Grant only the minimum permissions needed
2. **Defense in Depth**: Use multiple security layers
3. **Encryption**: Encrypt data at rest and in transit
4. **Audit Logging**: Enable logging for compliance and forensics
5. **Regular Scanning**: Integrate security scanning in CI/CD pipelines
6. **Version Control**: Enable versioning for important data
7. **Access Controls**: Restrict public access unless absolutely necessary
8. **Secrets Management**: Never hardcode credentials

## Detection Tools

- **Trivy**: IaC scanning (used in this practical)
- **tfsec**: Terraform-specific security scanner
- **Checkov**: Multi-language IaC scanner
- **terraform-compliance**: BDD-style compliance testing
- **Terrascan**: Policy-as-code for IaC

## References

- [AWS Security Best Practices](https://docs.aws.amazon.com/security/)
- [Trivy Documentation](https://trivy.dev/)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [OWASP IaC Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Infrastructure_as_Code_Security_Cheat_Sheet.html)

## Next Steps

1. Scan both configurations and compare results
2. Try to fix issues in the insecure configuration
3. Create your own test cases for other vulnerabilities
4. Integrate Trivy into a CI/CD pipeline
5. Explore other security scanning tools

Remember: Security is not a one-time task but an ongoing process!
