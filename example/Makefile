.PHONY: help init plan apply destroy format validate check show output refresh clean deploy

ENV ?= dev
AWS_REGION ?= us-east-1
PROJECT ?= dbtbuildkit-infra
GITHUB_ORG ?= $(shell git config --get remote.origin.url 2>/dev/null | sed -E 's/.*github\.com[:/]([^/]+)\/.*/\1/' | tr '[:upper:]' '[:lower:]' || echo 'dbtbuildkit')

GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m

help:
	@echo "$(GREEN)Available commands:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Environment variables:$(NC)"
	@echo "  ENV          Environment (dev, stg, prd) - default: $(ENV)"
	@echo "  AWS_REGION   AWS region - default: $(AWS_REGION)"
	@echo "  PROJECT      Project name - default: $(PROJECT)"
	@echo "  GITHUB_ORG   GitHub organization - default: $(GITHUB_ORG)"

init:
	@echo "$(GREEN)Initializing Terraform...$(NC)"
	@REPO_NAME="dbtbuildkit-infra"; \
	REPO_OWNER=$$(echo "$(GITHUB_ORG)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g'); \
	BUCKET_NAME="$(ENV)-$(AWS_REGION)-$$REPO_OWNER--tfstates"; \
	BUCKET_NAME=$$(echo $$BUCKET_NAME | sed -E 's/^-+|-+$$//g' | cut -c1-63); \
	STATE_KEY="$(ENV)/repo=$$REPO_NAME/terraform.tfstate"; \
	echo "Bucket: $$BUCKET_NAME"; \
	echo "State Key: $$STATE_KEY"; \
	terraform init \
		-backend-config="key=$$STATE_KEY" \
		-backend-config="bucket=$$BUCKET_NAME" \
		-backend-config="region=$(AWS_REGION)" \
		-backend-config="encrypt=true"
	@echo "$(GREEN)Initialization completed$(NC)"

plan:
	@echo "$(GREEN)Running terraform plan...$(NC)"
	terraform plan \
		-var="env=$(ENV)" \
		-var="aws_region=$(AWS_REGION)" \
		-var="project=$(PROJECT)" \
		-out=tfplan
	@echo "$(GREEN)Plan completed - saved to tfplan$(NC)"

apply:
	@echo "$(GREEN)Applying Terraform changes...$(NC)"
	@if [ -f tfplan ]; then \
		echo "$(GREEN)Using existing plan (tfplan)...$(NC)"; \
		terraform apply tfplan; \
	else \
		echo "$(YELLOW)Plan not found. Running apply directly...$(NC)"; \
		terraform apply \
			-var="env=$(ENV)" \
			-var="aws_region=$(AWS_REGION)" \
			-var="project=$(PROJECT)" \
			-auto-approve; \
	fi
	@echo "$(GREEN)Apply completed$(NC)"

destroy:
	@echo "$(RED)WARNING: This will destroy ALL resources!$(NC)"
	@read -p "Are you sure? Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ] || exit 1
	terraform destroy \
		-var="env=$(ENV)" \
		-var="aws_region=$(AWS_REGION)" \
		-var="project=$(PROJECT)" \
		-auto-approve
	@echo "$(RED)Resources destroyed$(NC)"

format:
	@echo "$(GREEN)Formatting Terraform files...$(NC)"
	terraform fmt -recursive
	@echo "$(GREEN)Formatting completed$(NC)"

validate:
	@echo "$(GREEN)Validating Terraform configuration...$(NC)"
	terraform validate
	@echo "$(GREEN)Validation completed$(NC)"

check: format validate ## Format and validate code

show:
	terraform show

output:
	terraform output

refresh:
	@echo "$(GREEN)Refreshing Terraform state...$(NC)"
	terraform refresh \
		-var="env=$(ENV)" \
		-var="aws_region=$(AWS_REGION)" \
		-var="project=$(PROJECT)"
	@echo "$(GREEN)State refreshed$(NC)"

clean:
	@echo "$(YELLOW)Cleaning temporary files...$(NC)"
	rm -rf .terraform .terraform.lock.hcl terraform.tfstate.d terraform.tfstate.backup tfplan tfplan-destroy
	@echo "$(GREEN)Cleanup completed$(NC)"

deploy: init plan apply
	@echo "$(GREEN)Deploy completed$(NC)"

.DEFAULT_GOAL := help
