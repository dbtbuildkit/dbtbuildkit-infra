.PHONY: help install format validate test docs clean pre-commit version

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
BLUE := \033[0;34m
NC := \033[0m

help: ## Show this help message
	@echo "$(GREEN)Available commands:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

install: ## Install development dependencies
	@echo "$(GREEN)Installing development dependencies...$(NC)"
	@if command -v pip >/dev/null 2>&1; then \
		pip install -r docs/requirements.txt; \
		pip install pre-commit; \
		pre-commit install; \
		echo "$(GREEN)Installation completed$(NC)"; \
	else \
		echo "$(RED)Error: pip not found. Please install Python and pip first.$(NC)"; \
		exit 1; \
	fi

format: ## Format Terraform and Python code
	@echo "$(GREEN)Formatting code...$(NC)"
	@if command -v terraform >/dev/null 2>&1; then \
		terraform fmt -recursive; \
		echo "$(GREEN)Terraform files formatted$(NC)"; \
	else \
		echo "$(YELLOW)Warning: terraform not found, skipping Terraform formatting$(NC)"; \
	fi
	@if command -v black >/dev/null 2>&1; then \
		find . -name "*.py" -not -path "./.venv/*" -not -path "./venv/*" -not -path "./.git/*" -exec black --line-length=100 {} \; || true; \
		echo "$(GREEN)Python files formatted$(NC)"; \
	else \
		echo "$(YELLOW)Warning: black not found, skipping Python formatting$(NC)"; \
	fi

validate: ## Validate Terraform configuration
	@echo "$(GREEN)Validating Terraform configuration...$(NC)"
	@if command -v terraform >/dev/null 2>&1; then \
		cd dbtbuildkit && terraform init -backend=false && terraform validate; \
		cd ../dbt && terraform init -backend=false && terraform validate; \
		echo "$(GREEN)Validation completed$(NC)"; \
	else \
		echo "$(RED)Error: terraform not found. Please install Terraform first.$(NC)"; \
		exit 1; \
	fi

lint: ## Run linters (pre-commit hooks)
	@echo "$(GREEN)Running linters...$(NC)"
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit run --all-files; \
	else \
		echo "$(YELLOW)Warning: pre-commit not found. Run 'make install' first.$(NC)"; \
	fi

test: validate lint ## Run all tests (validate + lint)

docs: ## Build documentation
	@echo "$(GREEN)Building documentation...$(NC)"
	@cd docs && \
	if [ -f requirements.txt ]; then \
		pip install -q -r requirements.txt; \
	fi && \
	make html
	@echo "$(GREEN)Documentation built at docs/_build/html/index.html$(NC)"

docs-serve: docs ## Build and serve documentation locally
	@echo "$(GREEN)Serving documentation at http://localhost:8000$(NC)"
	@cd docs/_build/html && python3 -m http.server 8000 || python -m SimpleHTTPServer 8000

docs-clean: ## Clean documentation build files
	@echo "$(YELLOW)Cleaning documentation build files...$(NC)"
	@cd docs && make clean
	@echo "$(GREEN)Documentation cleaned$(NC)"

clean: docs-clean ## Clean all temporary files
	@echo "$(YELLOW)Cleaning temporary files...$(NC)"
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@find . -type f -name "*.pyo" -delete 2>/dev/null || true
	@find . -type f -name "*.pyd" -delete 2>/dev/null || true
	@find . -type f -name ".DS_Store" -delete 2>/dev/null || true
	@echo "$(GREEN)Cleanup completed$(NC)"

pre-commit: ## Install pre-commit hooks
	@echo "$(GREEN)Installing pre-commit hooks...$(NC)"
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit install; \
		echo "$(GREEN)Pre-commit hooks installed$(NC)"; \
	else \
		echo "$(RED)Error: pre-commit not found. Run 'make install' first.$(NC)"; \
		exit 1; \
	fi

version: ## Show current version
	@echo "$(BLUE)Current version:$(NC) $$(cat VERSION 2>/dev/null || echo 'unknown')"

check: test ## Alias for test command

.DEFAULT_GOAL := help
