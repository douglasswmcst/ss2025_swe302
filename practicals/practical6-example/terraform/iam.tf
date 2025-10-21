# IAM configuration for S3 deployment
# Note: In a production environment, you would create IAM roles/users for deployment
# For LocalStack local development, we use test credentials configured in main.tf

# This file is kept for demonstration purposes and future expansion
# In production, you would add:
# - Deployment user with S3 write permissions
# - Assume roles for cross-account deployments
# - Service roles for Lambda functions (if added later)

# Example: Deployment user (commented out for LocalStack)
# resource "aws_iam_user" "deployer" {
#   name = "${var.project_name}-deployer"
#   path = "/"
#
#   tags = {
#     Name        = "Deployment User"
#     Environment = var.environment
#     Project     = var.project_name
#   }
# }
#
# resource "aws_iam_user_policy" "deployer_s3_access" {
#   name = "${var.project_name}-deployer-s3-policy"
#   user = aws_iam_user.deployer.name
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "s3:PutObject",
#           "s3:GetObject",
#           "s3:DeleteObject",
#           "s3:ListBucket"
#         ]
#         Resource = [
#           aws_s3_bucket.deployment.arn,
#           "${aws_s3_bucket.deployment.arn}/*"
#         ]
#       }
#     ]
#   })
# }
