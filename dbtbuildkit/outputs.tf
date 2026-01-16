# -*- coding: utf-8 -*-
# DbtBuildKit AWS module outputs

output "ecr_repository_url" {
  description = "ECR repository URL for Docker image push/pull"
  value       = aws_ecr_repository.this.repository_url
}

output "ecr_repository_name" {
  description = "Name of created ECR repository"
  value       = aws_ecr_repository.this.name
}

output "ecr_repository_arn" {
  description = "ARN of created ECR repository"
  value       = aws_ecr_repository.this.arn
}

output "github_connection_arn" {
  description = "GitHub connection ARN (created or existing)"
  value       = local.github_connection_arn
}

output "github_connection_name" {
  description = "GitHub connection name"
  value       = var.use_github_native ? local.github_connection_name : null
}

output "github_connection_id" {
  description = "GitHub connection ID (last part of ARN)"
  value       = var.use_github_native && local.github_connection_arn != null ? try(split("/", local.github_connection_arn)[length(split("/", local.github_connection_arn)) - 1], null) : null
}

output "github_connection_status" {
  description = "Connection status (PENDING, AVAILABLE, ERROR)"
  value       = var.use_github_native && var.create_github_connection && length(aws_codeconnections_connection.github) > 0 ? aws_codeconnections_connection.github[0].connection_status : (var.use_github_native && var.existing_github_connection_arn != null ? "EXISTING" : null)
}

output "github_connection_url" {
  description = "URL to complete connection authorization (if status PENDING)"
  value       = var.use_github_native && var.create_github_connection && length(aws_codeconnections_connection.github) > 0 && aws_codeconnections_connection.github[0].connection_status == "PENDING" ? "https://console.aws.amazon.com/codesuite/settings/connections" : null
}
