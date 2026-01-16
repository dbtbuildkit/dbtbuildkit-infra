# -*- coding: utf-8 -*-

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.38.0"
    }
  }
  required_version = ">= 0.15.0"
}

locals {
  default_required_tags = {
    owner      = "ari@henrique.com"
    env        = terraform.workspace
    managed-by = "terraform"
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.default_required_tags
  }
}