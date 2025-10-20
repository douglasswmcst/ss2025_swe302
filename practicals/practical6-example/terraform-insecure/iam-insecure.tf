# INTENTIONALLY INSECURE IAM CONFIGURATION
# This file demonstrates common IAM security misconfigurations
# DO NOT use this in production!

# ISSUE 1: Overly permissive IAM policy with wildcard actions
resource "aws_iam_role" "insecure_role" {
  name = "insecure-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ISSUE 2: Administrator access - violates least privilege principle
resource "aws_iam_role_policy" "insecure_policy" {
  name = "insecure-policy"
  role = aws_iam_role.insecure_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",           # All S3 actions
          "dynamodb:*",     # All DynamoDB actions
          "ec2:*",          # All EC2 actions
          "iam:*"           # All IAM actions - EXTREMELY DANGEROUS!
        ]
        Resource = "*"      # ISSUE 3: Wildcard resource
      }
    ]
  })
}

# ISSUE 4: Hardcoded credentials (simulated)
# In real scenarios, never hardcode access keys
resource "aws_iam_access_key" "insecure_key" {
  user = aws_iam_user.insecure_user.name
}

resource "aws_iam_user" "insecure_user" {
  name = "service-account"
  path = "/"

  # ISSUE 5: No MFA enforcement
  # ISSUE 6: No password policy
}

# ISSUE 7: User with admin permissions
resource "aws_iam_user_policy_attachment" "admin_attach" {
  user       = aws_iam_user.insecure_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ISSUE 8: No password rotation policy
# ISSUE 9: No access key rotation
# ISSUE 10: No CloudTrail logging for IAM actions
