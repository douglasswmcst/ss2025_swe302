output "source_bucket_name" {
  description = "Name of the source S3 bucket"
  value       = aws_s3_bucket.source.id
}

output "artifacts_bucket_name" {
  description = "Name of the artifacts S3 bucket"
  value       = aws_s3_bucket.artifacts.id
}

output "deployment_bucket_name" {
  description = "Name of the deployment S3 bucket"
  value       = aws_s3_bucket.deployment.id
}

output "deployment_website_endpoint" {
  description = "Website endpoint URL"
  value       = "http://${aws_s3_bucket.deployment.bucket}.s3-website.localhost.localstack.cloud:4566"
}

output "pipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.nextjs_pipeline.name
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = aws_codebuild_project.nextjs_build.name
}

output "upload_command" {
  description = "Command to upload source code"
  value       = "awslocal s3 cp nextjs-app.zip s3://${aws_s3_bucket.source.bucket}/${var.source_zip_key}"
}

output "trigger_pipeline_command" {
  description = "Command to trigger pipeline execution"
  value       = "awslocal codepipeline start-pipeline-execution --name ${aws_codepipeline.nextjs_pipeline.name}"
}
