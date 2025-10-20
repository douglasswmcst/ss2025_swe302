variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "practical6"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "source_zip_key" {
  description = "S3 key for source code ZIP file"
  type        = string
  default     = "nextjs-app.zip"
}
