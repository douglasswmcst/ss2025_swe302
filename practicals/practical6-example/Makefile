.PHONY: help setup deploy status clean destroy scan scan-insecure scan-all compare-security dev init deploy-github verify rollback watch

help: ## Show this help message
	@echo "Practical 6 - Infrastructure as Code with Terraform"
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Start LocalStack
	@./scripts/setup.sh

deploy: ## Deploy infrastructure and application
	@./scripts/deploy.sh

status: ## Check deployment status
	@./scripts/status.sh

clean: ## Clean up everything
	@./scripts/cleanup.sh

destroy: clean ## Alias for clean

dev: ## Quick development cycle: build and deploy app only
	@echo "Building Next.js app..."
	@cd nextjs-app && npm run build
	@echo "Deploying to S3..."
	@cd terraform && awslocal s3 sync ../nextjs-app/out/ s3://$$(terraform output -raw deployment_bucket_name)/ --delete
	@echo "Done! Check status with 'make status'"

website: ## Open website in browser
	@cd terraform && open $$(terraform output -raw deployment_website_endpoint)

init: ## Initialize all dependencies
	@echo "Installing Next.js dependencies..."
	@cd nextjs-app && npm ci
	@echo "Initializing Terraform..."
	@cd terraform && tflocal init
	@echo "Dependencies installed!"

scan: ## Scan Terraform for security issues
	@./scripts/scan.sh terraform

scan-insecure: ## Scan insecure Terraform configuration
	@./scripts/scan.sh insecure

scan-all: ## Scan all Terraform configurations
	@./scripts/scan.sh all

compare-security: ## Compare secure vs insecure configurations
	@./scripts/compare-security.sh

# GitHub-based deployment commands (Practical 6a)
deploy-github: ## Deploy from GitHub repository
	@./scripts/deploy-from-github.sh

verify: ## Verify deployment
	@./scripts/verify-deployment.sh

rollback: ## Rollback to previous commit (usage: make rollback COMMIT=abc123)
	@./scripts/rollback.sh $(COMMIT)

watch: ## Watch GitHub repo and auto-deploy on changes
	@./scripts/watch-and-deploy.sh
