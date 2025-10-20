# INTENTIONALLY INSECURE TERRAFORM CONFIGURATION
# This file demonstrates common security misconfigurations
# DO NOT use this in production!

resource "aws_s3_bucket" "insecure_example" {
  bucket = "insecure-example-bucket"

  tags = {
    Name        = "Insecure Example"
    Environment = "dev"
  }
}

# ISSUE 1: No encryption enabled
# Buckets should always use server-side encryption

# ISSUE 2: No versioning
# Version control helps with data recovery and compliance

# ISSUE 3: No access logging
resource "aws_s3_bucket_public_access_block" "insecure_example" {
  bucket = aws_s3_bucket.insecure_example.id

  # ISSUE 4: Public access allowed
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ISSUE 5: Overly permissive bucket policy
resource "aws_s3_bucket_policy" "insecure_example" {
  bucket = aws_s3_bucket.insecure_example.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadWriteAccess"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"  # DANGEROUS: Anyone can delete objects!
        ]
        Resource = "${aws_s3_bucket.insecure_example.arn}/*"
      }
    ]
  })
}

# Another insecure bucket
resource "aws_s3_bucket" "backup_insecure" {
  bucket = "backup-insecure-bucket"

  # ISSUE 6: No tags for governance
}

# ISSUE 7: No lifecycle policies to manage costs
# ISSUE 8: No MFA delete protection for versioned buckets
