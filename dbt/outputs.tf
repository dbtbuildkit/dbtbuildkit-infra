# -*- coding: utf-8 -*-
# File name infra/modules/dbt/outputs.tf


output "codebuild_projects" {
  description = "List of CodeBuild projects created for DBT execution"
  value = {
    for name, project in aws_codebuild_project.dbt_projects : name => {
      arn  = project.arn
      name = project.name
      url  = "https://console.aws.amazon.com/codesuite/codebuild/projects/${project.name}/history"
    }
  }
}

output "scheduled_projects" {
  description = "List of DBT projects with scheduled execution"
  value = {
    for name, rule in aws_cloudwatch_event_rule.codebuild_schedule : name => {
      name     = rule.name
      schedule = rule.schedule_expression
      state    = rule.state
    }
  }
}

output "manual_projects" {
  description = "List of DBT projects for manual execution"
  value = [
    for project in local.filtered_projects : project.name
    if lookup(project, "schedule", null) == null
  ]
}

output "active_projects_summary" {
  description = "Summary of active DBT projects in the environment"
  value = {
    for project in local.validated_projects : project.name => {
      repo               = project.repo
      org                = project.org
      engine             = project.engine
      schedule           = lookup(project, "schedule", "manual")
      timeout            = lookup(project, "timeout", 60)
      slack_notification = lookup(project, "slack-notification", {})
      incident_manager   = lookup(project, "incident-manager", {})
      elementary         = lookup(project, "elementary", {})
    }
  }
}

output "debug_schedules" {
  description = "Debug of processed schedule expressions"
  value       = local.process_schedule
}

output "codebuild_iam_role_arn" {
  description = "ARN of IAM role used by CodeBuild projects"
  value       = local.should_create_resources ? aws_iam_role.codebuild_role[0].arn : null
}

output "events_iam_role_arn" {
  description = "ARN of IAM role used by CloudWatch Events to schedule executions"
  value       = length(local.scheduled_projects) > 0 ? aws_iam_role.events_role[0].arn : null
}
