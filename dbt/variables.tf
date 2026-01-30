# -*- coding: utf-8 -*-
# File name variables.tf

variable "project" {
  description = "Project name for identification and organization of AWS resources"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "Project name must contain only lowercase letters, numbers and hyphens"
  }
}

variable "env" {
  description = "Deployment environment (accepted values: dev, stg, prd)"
  type        = string
  validation {
    condition     = contains(["dev", "stg", "prd"], var.env)
    error_message = "Environment must be one of: dev, stg, prd"
  }
}

variable "aws_region" {
  description = "AWS region where resources will be created (e.g.: us-east-1, sa-east-1)"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2,3}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must follow standard format (e.g.: us-east-1)"
  }
}

variable "ecr_dbt" {
  description = "ECR repository name containing the DBT Docker image (without environment prefix)"
  type        = string
  default     = "dbtbuildkit"
}

variable "ecr_image_uri" {
  description = "Complete URI of the DBT Docker image in ECR. If provided, overrides automatic construction based on ecr_dbt. Format: <account-id>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>"
  type        = string
  default     = null
}

variable "ecr_image_tag" {
  description = "Docker image tag for DBT in ECR"
  type        = string
  default     = "latest"
}

variable "tags" {
  description = "Map of common tags applied to all module resources"
  type        = map(string)
}


variable "file_name" {
  type        = string
  default     = "dbt_project.yml"
  description = "Configuration file for CodeBuild projects (dbt_project.yml or codebuild-config.yml). When using dbt_project.yml, add a top-level 'dbtbuildkit' key with a list of projects."
}

variable "folder_name" {
  type        = string
  default     = "."
  description = "Folder name for the codebuild configuration file"
}

variable "use_github_native" {
  description = "If true, uses native GitHub integration. If false, uses SSH as fallback."
  type        = bool
  default     = true
}

variable "github_branch" {
  description = "GitHub repository branch to use (e.g.: main, develop)"
  type        = string
  default     = "main"
}

variable "github_connection_arn" {
  description = "GitHub connection ARN for native integration. Required when use_github_native = true"
  type        = string
  default     = null
}

variable "incident_response_plan_default" {
  description = "Default incident response plan name used when not specified in the project"
  type        = string
  default     = ""
}

variable "iam_policy_statements" {
  description = "List of custom IAM statements to add to CodeBuild policy. If not provided, uses default broad permissions"
  type = list(object({
    Effect   = string
    Action   = list(string)
    Resource = string
  }))
  default = []
}

variable "enable_default_iam_permissions" {
  description = "If true, adds default broad permissions for DBT (S3, Athena, Redshift, Glue, etc). If false, uses only iam_policy_statements"
  type        = bool
  default     = true
}

variable "use_minimal_iam_policy" {
  description = "If true, uses minimal and restrictive IAM policy. If false, uses broad policy with wildcards. Requires enable_default_iam_permissions = true"
  type        = bool
  default     = false
}

variable "s3_buckets" {
  description = "List of allowed S3 buckets for access (used only with use_minimal_iam_policy = true). If empty, allows all buckets"
  type        = list(string)
  default     = []
}

variable "secrets_manager_secrets" {
  description = "List of allowed Secrets Manager secret ARNs (used only with use_minimal_iam_policy = true). If empty, allows all secrets"
  type        = list(string)
  default     = []
}

variable "ecr_repository_arns" {
  description = "List of allowed ECR repository ARNs (used only with use_minimal_iam_policy = true). If empty, allows all repositories"
  type        = list(string)
  default     = []
}

variable "codebuild_role_name_suffix" {
  description = "Custom suffix for CodeBuild role name. If not provided, uses 'codebuild-role'"
  type        = string
  default     = "codebuild-role"
}

variable "events_role_name_suffix" {
  description = "Custom suffix for Events role name. If not provided, uses 'events-role'"
  type        = string
  default     = "events-role"
}

variable "additional_iam_policy_arns" {
  description = "List of managed IAM policy ARNs to attach to CodeBuild role. Useful for adding additional permissions without modifying the default policy"
  type        = list(string)
  default     = []
}