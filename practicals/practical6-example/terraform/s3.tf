# S3 bucket for deployment (website hosting)
resource "aws_s3_bucket" "deployment" {
  bucket = "${var.project_name}-deployment-${var.environment}"

  tags = {
    Name        = "Deployment Bucket"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Configure deployment bucket for static website hosting
resource "aws_s3_bucket_website_configuration" "deployment" {
  bucket = aws_s3_bucket.deployment.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

# Enable encryption for deployment bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "deployment" {
  bucket = aws_s3_bucket.deployment.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Make deployment bucket public (for static website access)
resource "aws_s3_bucket_public_access_block" "deployment" {
  bucket = aws_s3_bucket.deployment.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy to allow public read access
resource "aws_s3_bucket_policy" "deployment" {
  bucket = aws_s3_bucket.deployment.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.deployment.arn}/*"
      }
    ]
  })
}

# S3 bucket for access logs
resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-logs-${var.environment}"

  tags = {
    Name        = "Access Logs Bucket"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Enable access logging for deployment bucket
resource "aws_s3_bucket_logging" "deployment" {
  bucket = aws_s3_bucket.deployment.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "deployment-logs/"
}
