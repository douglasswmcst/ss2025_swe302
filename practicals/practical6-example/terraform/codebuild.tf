resource "aws_codebuild_project" "nextjs_build" {
  name          = "${var.project_name}-build"
  description   = "Build Next.js application"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false

    environment_variable {
      name  = "NODE_ENV"
      value = "production"
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "NEXT_TELEMETRY_DISABLED"
      value = "1"
      type  = "PLAINTEXT"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
  }

  tags = {
    Name        = "Next.js Build Project"
    Environment = var.environment
    Project     = var.project_name
  }
}
