terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"

  # Skip AWS-specific validations
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # S3 configuration for LocalStack
  s3_use_path_style = true

  # Configure all service endpoints to point to LocalStack
  endpoints {
    s3             = "http://localhost:4566"
    iam            = "http://localhost:4566"
    codepipeline   = "http://localhost:4566"
    codebuild      = "http://localhost:4566"
    sts            = "http://localhost:4566"
    logs           = "http://localhost:4566"
  }
}
