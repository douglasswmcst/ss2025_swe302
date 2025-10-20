.PHONY: help setup deploy status logs clean destroy scan scan-insecure scan-all compare-security

help: ## Show this help message
	@echo "Practical 6 - Infrastructure as Code with Terraform"
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Start LocalStack
	@./scripts/setup.sh

deploy: ## Deploy full infrastructure and application
	@./scripts/deploy.sh

status: ## Check deployment status
	@./scripts/status.sh

logs: ## Tail CodeBuild logs (requires PIPELINE_NAME)
	@cd terraform && awslocal logs tail /aws/codebuild/$$(terraform output -raw codebuild_project_name) --follow

clean: ## Clean up everything
	@./scripts/cleanup.sh

destroy: clean ## Alias for clean

dev: ## Quick development cycle: build and deploy
	@echo "Building Next.js app..."
	@cd nextjs-app && npm run build
	@echo "Packaging app..."
	@cd nextjs-app/out && zip -r ../../nextjs-app.zip . > /dev/null
	@echo "Uploading to S3..."
	@cd terraform && awslocal s3 cp ../nextjs-app.zip s3://$$(terraform output -raw source_bucket_name)/nextjs-app.zip
	@echo "Triggering pipeline..."
	@cd terraform && awslocal codepipeline start-pipeline-execution --name $$(terraform output -raw pipeline_name)
	@echo "Done! Use 'make status' to check progress"

website: ## Open website in browser
	@cd terraform && open $$(terraform output -raw deployment_website_endpoint)

init: ## Initialize all dependencies
	@echo "Installing Next.js dependencies..."
	@cd nextjs-app && npm ci
	@echo "Initializing Terraform..."
	@cd terraform && terraform init
	@echo "Dependencies installed!"

scan: ## Scan Terraform for security issues
	@./scripts/scan.sh terraform

scan-insecure: ## Scan insecure Terraform configuration
	@./scripts/scan.sh insecure

scan-all: ## Scan all Terraform configurations
	@./scripts/scan.sh all

compare-security: ## Compare secure vs insecure configurations
	@./scripts/compare-security.sh
