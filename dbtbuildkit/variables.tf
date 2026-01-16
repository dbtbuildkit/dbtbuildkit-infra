# -*- coding: utf-8 -*-
# DbtBuildKit AWS module variables

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
  description = "AWS region where resources will be created"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2,3}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must follow standard format (e.g.: us-east-1)"
  }
}

variable "use_github_native" {
  description = "If true, uses native GitHub integration via CodeConnections. If false, uses SSH"
  type        = bool
  default     = true
}

variable "create_github_connection" {
  description = "If true, creates a new GitHub connection. If false, uses existing connection (via existing_github_connection_arn)"
  type        = bool
  default     = true
}


variable "existing_github_connection_arn" {
  description = "ARN of an existing GitHub connection to use. If provided, does not create new connection"
  type        = string
  default     = null
}

variable "github_organization" {
  description = "GitHub organization (required). Will be used in CodeConnections connection name: {env}-{org}-github-connection. Required for dbt to extract organization name."
  type        = string
  validation {
    condition     = var.github_organization != null && var.github_organization != ""
    error_message = "github_organization is required and cannot be empty. It is necessary for dbt to extract the organization name."
  }
}

variable "wait_for_connection_approval" {
  description = "If true, waits for manual GitHub connection approval in AWS console before continuing"
  type        = bool
  default     = true
}

variable "connection_wait_timeout_minutes" {
  description = "Maximum time (in minutes) to wait for GitHub connection approval"
  type        = number
  default     = 30
}

variable "connection_check_interval_seconds" {
  description = "Interval (in seconds) between GitHub connection status checks"
  type        = number
  default     = 10
}

# ECR variables
variable "ecr_repository_name" {
  description = "ECR repository name. If not provided, uses default: {env}-dbtbuildkit"
  type        = string
  default     = null
  nullable    = true
}

variable "ecr_repository_name_exact" {
  description = "If true, uses exact repository name. If false, adds prefix {env}-{project}-"
  type        = bool
  default     = true
}

variable "ecr_image_tag" {
  description = "Docker image tag in ECR repository"
  type        = string
  default     = "latest"
}

variable "ecr_image_tag_mutability" {
  description = "Image tag mutability in ECR"
  type        = string
  default     = "MUTABLE"
}

variable "ecr_scan_on_push" {
  description = "Enables image scan on push"
  type        = bool
  default     = true
}

variable "ecr_days_lifecycle_policy" {
  description = "Number of images to retain in lifecycle policy"
  type        = number
  default     = 5
}

variable "tags" {
  description = "Map of common tags applied to all module resources"
  type        = map(string)
}