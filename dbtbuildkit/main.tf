# -*- coding: utf-8 -*-
# DbtBuildKit AWS module - Automatically integrates ECR and GitHub Connection

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  common_tags    = var.tags




  ecr_repository_name_raw = var.ecr_repository_name != null ? var.ecr_repository_name : "${var.env}-dbtbuildkit"
  ecr_repository_name     = var.ecr_repository_name_exact ? local.ecr_repository_name_raw : lower("${var.env}-${var.project}-${local.ecr_repository_name_raw}")
  ecr_folder_path         = "${path.module}/docker"
  specific_files          = ["Dockerfile", "pyproject.toml", "dbt-kit"]



  file_triggers = {
    for file in local.specific_files : file => filesha256("${local.ecr_folder_path}/${file}")
    if fileexists("${local.ecr_folder_path}/${file}")
  }





  github_connection_name_base = "${var.env}-${var.github_organization}-gh-conn"
  github_connection_name = length(local.github_connection_name_base) > 32 ? substr(local.github_connection_name_base, 0, 32) : local.github_connection_name_base
  github_connection_arn  = var.create_github_connection && var.use_github_native ? aws_codeconnections_connection.github[0].arn : var.existing_github_connection_arn
}


# ECR - Repository and Docker image build

resource "aws_ecr_repository" "this" {
  name                 = local.ecr_repository_name
  image_tag_mutability = var.ecr_image_tag_mutability
  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }
  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "delete" {
  repository = aws_ecr_repository.this.name
  policy     = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep only the most recent images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": ${var.ecr_days_lifecycle_policy}
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "null_resource" "run_script" {

  triggers = merge(local.file_triggers, {

    config = md5(jsonencode({
      folder          = local.ecr_folder_path
      region          = var.aws_region
      repository_name = local.ecr_repository_name
      tag_image       = var.ecr_image_tag
    }))
  })

  provisioner "local-exec" {
    command = "chmod +x ${path.module}/scripts/script.sh && ${path.module}/scripts/script.sh"
    environment = {
      FOLDER         = local.ecr_folder_path
      AWS_REGION     = var.aws_region
      AWS_ACCOUNT_ID = local.aws_account_id
      ECR_REPO_NAME  = aws_ecr_repository.this.name
      IMAGE_TAG      = var.ecr_image_tag
    }
    interpreter = ["/bin/bash", "-c"]
  }
}

# ============================================================================
# GitHub Connection - GitHub connection via AWS CodeConnections
# ============================================================================

resource "aws_codeconnections_connection" "github" {
  count = var.use_github_native && var.create_github_connection ? 1 : 0

  name          = local.github_connection_name
  provider_type = "GitHub"

  tags = merge(local.common_tags, {
    Name        = local.github_connection_name
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [

    ]
  }
}

# Waits for manual GitHub connection approval in AWS console
resource "null_resource" "wait_for_github_connection" {
  count = var.use_github_native && var.create_github_connection && var.wait_for_connection_approval ? 1 : 0

  depends_on = [aws_codeconnections_connection.github]

  triggers = {
    connection_arn = aws_codeconnections_connection.github[0].arn
    connection_status = aws_codeconnections_connection.github[0].connection_status
  }

  provisioner "local-exec" {
    command = <<-EOT
      chmod +x ${path.module}/scripts/wait_for_github_connection.sh
      ${path.module}/scripts/wait_for_github_connection.sh \
        "${aws_codeconnections_connection.github[0].arn}" \
        "${var.aws_region}" \
        "${var.connection_wait_timeout_minutes}" \
        "${var.connection_check_interval_seconds}"
    EOT

    interpreter = ["/bin/bash", "-c"]
  }
}