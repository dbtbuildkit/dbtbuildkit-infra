# -*- coding: utf-8 -*-

module "project" {
  source     = "git::https://dbtbuildkit/dbtbuildkit-infra.git//dbtbuildkit?ref=main"
  aws_region = var.aws_region
  env        = var.env
  project    = var.project
  tags       = local.common_tags
  github_organization = var.github_organization
}

module "dbt_project" {
  source = "git::https://dbtbuildkit/dbtbuildkit-infra.git//dbtbuildkit?ref=main"
  project = "dbt-project"
  aws_region = var.aws_region
  env        = var.env
  tags       = local.common_tags
  depends_on = [ module.project ]
}