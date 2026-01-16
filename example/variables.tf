# -*- coding: utf-8 -*-

variable "project" {
  description = "Project name"
  type        = string
  default     = "project-example"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "prd"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "author" {
  description = "Repository creator"
  type        = string
  default     = "AriHenrique"
}

variable "github_organization" {
  description = "GitHub organization. Will be included in CodeConnections connection name (e.g.: prd-{org}-github-connection)"
  type        = string
  default     = "dbtbuildkit"
}


locals {
  common_tags = {
    env              = var.env
    author           = var.author
    project          = var.project
    data_sensitivity = "Confidential"
    purpose          = "ETL_Process"
    department       = "Operations"
    cost_center      = "DataOps"
    version          = "v1.0"
  }
}
