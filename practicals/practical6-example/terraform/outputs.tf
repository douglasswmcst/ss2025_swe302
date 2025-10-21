output "deployment_bucket_name" {
  description = "Name of the deployment S3 bucket"
  value       = aws_s3_bucket.deployment.id
}

output "logs_bucket_name" {
  description = "Name of the logs S3 bucket"
  value       = aws_s3_bucket.logs.id
}

output "deployment_website_endpoint" {
  description = "Website endpoint URL"
  value       = "http://${aws_s3_bucket.deployment.bucket}.s3-website.localhost.localstack.cloud:4566"
}

output "deploy_command" {
  description = "Command to deploy the Next.js application"
  value       = "awslocal s3 sync ../nextjs-app/out/ s3://${aws_s3_bucket.deployment.bucket}/ --delete"
}

output "list_files_command" {
  description = "Command to list deployed files"
  value       = "awslocal s3 ls s3://${aws_s3_bucket.deployment.bucket}/ --recursive"
}
