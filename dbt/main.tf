# -*- coding: utf-8 -*-
# File name main.tf
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
    external = {
      source  = "hashicorp/external"
      version = ">= 2.0.0"
    }
  }
}

data "aws_caller_identity" "current" {}

data "external" "codeconnections" {
  program = ["${path.module}/scripts/list_codeconnections.sh", var.aws_region]
  


}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  


  codeconnections_list = try(jsondecode(data.external.codeconnections.result.connections), [])
  



  default_ecr_image_uri = var.ecr_image_uri != null ? var.ecr_image_uri : "${local.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.env}-${var.ecr_dbt}:${var.ecr_image_tag}"



  project_ecr_image_uris = {
    for project in local.filtered_projects : project.name => (
      try(project.ecr_repository, null) != null ?
      "${local.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${project.ecr_repository}:${try(project.ecr_image_tag, var.ecr_image_tag)}" :
      local.default_ecr_image_uri
    )
  }


  minimal_iam_policy_statements = [

    {
      Effect = "Allow"
      Action = [
        "sts:GetCallerIdentity"
      ]
      Resource = "*"
    },

    {
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:${var.aws_region}:${local.aws_account_id}:log-group:/aws/codebuild/*"
    },

    {
      Effect = "Allow"
      Action = length(var.s3_buckets) > 0 ? [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
        ] : [
        "s3:GetObject",
        "s3:PutObject"
      ]
      Resource = length(var.s3_buckets) > 0 ? concat(
        [for bucket in var.s3_buckets : "arn:aws:s3:::${bucket}"],
        [for bucket in var.s3_buckets : "arn:aws:s3:::${bucket}/*"]
      ) : ["*"]
    },

    {
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = length(var.secrets_manager_secrets) > 0 ? var.secrets_manager_secrets : [
        "arn:aws:secretsmanager:${var.aws_region}:${local.aws_account_id}:secret:*"
      ]
    },

    {
      Effect = "Allow"
      Action = [
        "sns:Publish"
      ]
      Resource = "*"
    },

    {
      Effect = "Allow"
      Action = [
        "ecr:GetAuthorizationToken"
      ]
      Resource = "*"
    },
    {
      Effect = "Allow"
      Action = [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ]
      Resource = length(var.ecr_repository_arns) > 0 ? var.ecr_repository_arns : [
        "arn:aws:ecr:${var.aws_region}:${local.aws_account_id}:repository/*"
      ]
    },

    {
      Effect = "Allow"
      Action = [
        "ssm-incidents:ListResponsePlans",
        "ssm-incidents:StartIncident",
        "ssm-incidents:CreateTimelineEvent",
        "ssm-incidents:GetIncidentRecord"
      ]
      Resource = "*"
    },

    {
      Effect = "Allow"
      Action = [
        "ssm-contacts:GetContact",
        "ssm-contacts:ListContacts"
      ]
      Resource = "*"
    },


  ]


  engine_specific_permissions = {
    redshift = [
      {
        Effect = "Allow"
        Action = [
          "redshift-data:ExecuteStatement",
          "redshift-data:DescribeStatement",
          "redshift-data:GetStatementResult",
          "redshift:DescribeClusters"
        ]
        Resource = "*"
      }
    ]
    athena = [
      {
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution",
          "athena:StopQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:GetWorkGroup",
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetPartitions",
          "glue:CreateTable",
          "glue:UpdateTable"
        ]
        Resource = "*"
      }
    ]
    glue = [
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetPartitions",
          "glue:CreateTable",
          "glue:UpdateTable",
          "glue:DeleteTable",
          "glue:GetJob",
          "glue:StartJobRun"
        ]
        Resource = "*"
      }
    ]
    snowflake  = []
    bigquery   = []
    postgres   = []
    databricks = []
  }


  broad_iam_policy_statement = {
    Effect = "Allow"
    Action = [
      "sts:*",
      "logs:*",
      "s3:*",
      "athena:*",
      "redshift:*",
      "redshift-data:*",
      "glue:*",
      "secretsmanager:*",
      "ecr:*",
      "ssm-incidents:*",
      "ssm-contacts:*",
      "ec2:*",
      "codeconnections:*",
      "dynamodb:*",
      "sns:*"
    ]
    Resource = "*"
  }


  config_file_path = "${path.root}/${var.folder_name == "." ? "" : var.folder_name}/${var.file_name}"


  config_file_exists = fileexists(local.config_file_path)


  raw_config = local.config_file_exists ? file(local.config_file_path) : "codebuild: []"



  uncommented_lines = [
    for line in split("\n", local.raw_config) :
    trimspace(line) if trimspace(line) != "" && !startswith(trimspace(line), "#")
  ]

  has_valid_content = local.config_file_exists && length(local.uncommented_lines) > 0


  codebuild_config = yamldecode(local.raw_config)


  codebuild_list = try(local.codebuild_config.codebuild, [])


  active_projects = [
    for project in local.codebuild_list : project if try(project.active, false)
  ]


  validated_projects = [
    for project in local.active_projects : project
    if can(project.name) && can(project.repo) && can(project.org) && can(project.engine) && can(project.commands)
  ]


  filtered_projects = local.validated_projects


  unique_orgs = toset([
    for project in local.filtered_projects : try(project.org, "")
    if try(project.org, "") != ""
  ])
  






  org_to_connection_arn = {
    for org in local.unique_orgs :
    org => try([
      for conn in local.codeconnections_list :
      conn.arn if (

        try(conn.status, "") == "AVAILABLE" &&
        (


          can(regex("(?i)(^|[^a-z0-9])${org}([^a-z0-9]|$)", try(conn.name, ""))) ||

          contains(try(conn.possible_orgs, []), org) ||

          can(regex("(?i)${org}", try(conn.name, "")))
        )
      )
    ][0], null)
    if org != ""
  }
  



  provided_connection_status = var.github_connection_arn != null && var.github_connection_arn != "" ? (
    try([
      for conn in local.codeconnections_list :
      conn.status if conn.arn == var.github_connection_arn
    ][0], "UNKNOWN")
  ) : null
  
  provided_connection_available = local.provided_connection_status == "AVAILABLE"
  





  github_connection_arn = var.github_connection_arn != null && var.github_connection_arn != "" ? var.github_connection_arn : (
    length(local.unique_orgs) > 0 ? try([
      for org in local.unique_orgs :
      local.org_to_connection_arn[org] if local.org_to_connection_arn[org] != null
    ][0], null) : null
  )
  



  determined_connection_status = local.github_connection_arn != null ? (
    var.github_connection_arn != null && var.github_connection_arn != "" && var.github_connection_arn == local.github_connection_arn ? (

      local.provided_connection_status != null ? local.provided_connection_status : "AVAILABLE"
    ) : (


      try([
        for conn in local.codeconnections_list :
        conn.status if conn.arn == local.github_connection_arn
      ][0], "AVAILABLE")
    )
  ) : null
  




  github_connection_available = local.github_connection_arn != null && (
    var.github_connection_arn != null && var.github_connection_arn != "" && var.github_connection_arn == local.github_connection_arn ? (

      true
    ) : (


      true
    )
  )

  scheduled_projects = [for project in local.filtered_projects : project if lookup(project, "schedule", null) != null]


  should_create_resources = local.has_valid_content && length(local.filtered_projects) > 0


  process_schedule = {
    for project in local.scheduled_projects : project.name => {
      original_schedule = project.schedule
      cleaned_schedule  = replace(project.schedule, "'", "")


      final_expression = startswith(trimspace(replace(project.schedule, "'", "")), "cron(") || startswith(trimspace(replace(project.schedule, "'", "")), "rate(") ? replace(project.schedule, "'", "") : "cron(${replace(project.schedule, "'", "")})"
    }
  }
}

resource "aws_iam_role" "codebuild_role" {
  count = local.should_create_resources ? 1 : 0

  name = "${var.env}-${var.project}-${var.codebuild_role_name_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "codebuild_additional_policies" {
  for_each = local.should_create_resources && length(var.additional_iam_policy_arns) > 0 ? toset(var.additional_iam_policy_arns) : toset([])

  role       = aws_iam_role.codebuild_role[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "codebuild_policy" {
  count = local.should_create_resources ? 1 : 0

  role = aws_iam_role.codebuild_role[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(

      var.enable_default_iam_permissions ? (
        var.use_minimal_iam_policy ? (

          tolist(concat(
            local.minimal_iam_policy_statements,


            var.use_github_native && local.github_connection_arn != null ? [
              {
                Effect = "Allow"
                Action = [
                  "codeconnections:UseConnection"
                ]
                Resource = [local.github_connection_arn]
              }
            ] : [],

            flatten([
              for project in local.filtered_projects :
              try(local.engine_specific_permissions[lower(project.engine)], [])
            ]),

            flatten([
              for project in local.filtered_projects :
              try(project.vpc_config, null) != null ? [
                {
                  Effect = "Allow"
                  Action = [
                    "ec2:DescribeNetworkInterfaces",
                    "ec2:CreateNetworkInterface",
                    "ec2:DeleteNetworkInterface",
                    "ec2:DescribeSecurityGroups",
                    "ec2:DescribeSubnets",
                    "ec2:DescribeVpcs"
                  ]
                  Resource = "*"
                }
              ] : []
            ])
          ))
        ) : tolist([


          local.broad_iam_policy_statement
        ])
      ) : [],

      var.iam_policy_statements
    )
  })
}

resource "null_resource" "validate_github_connection" {
  count = var.use_github_native && local.should_create_resources ? 1 : 0


  triggers = {
    github_connection_arn = local.github_connection_arn
    connection_status      = local.determined_connection_status
  }



  provisioner "local-exec" {
    command = "chmod +x ${path.module}/scripts/validate_github_connection.sh && ${path.module}/scripts/validate_github_connection.sh \"${coalesce(local.github_connection_arn, "null")}\" \"${var.aws_region}\""
  }
}

resource "aws_codebuild_project" "dbt_projects" {
  for_each = { for project in local.filtered_projects : project.name => project }

  name         = "${var.env}-${each.value.name}"
  service_role = aws_iam_role.codebuild_role[0].arn




  depends_on = [
    data.external.codeconnections,
    null_resource.validate_github_connection
  ]

  artifacts {
    type = "NO_ARTIFACTS"
  }

  build_timeout = lookup(each.value, "timeout", 60)

  environment {
    compute_type                = lookup(each.value, "compute_type", "BUILD_GENERAL1_SMALL")
    image                       = lower(local.project_ecr_image_uris[each.value.name])
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "ENGINE"
      value = each.value.engine
    }

    environment_variable {
      name  = "ELEMENTARY_ENABLED"
      value = tostring(try(each.value.elementary.active, try(each.value.elementary, false), false))
    }

    environment_variable {
      name  = "SLACK_NOTIFICATION"
      value = tostring(try(each.value["slack-notification"].active, try(each.value["slack-notification"], false), false))
    }

    environment_variable {
      name  = "SLACK_CHANNEL"
      value = try(each.value["slack-notification"].channel, null)
    }

    environment_variable {
      name  = "SLACK_SECRET_NAME"
      value = try(each.value["slack-notification"].secret_name, null)
    }

    environment_variable {
      name  = "TEAMS_NOTIFICATION"
      value = tostring(try(each.value["teams-notification"].active, try(each.value["teams-notification"], false), false))
    }

    environment_variable {
      name  = "TEAMS_SECRET_NAME"
      value = try(each.value["teams-notification"].secret_name, null)
    }

    environment_variable {
      name  = "TEAMS_WEBHOOK_URL"
      value = try(each.value["teams-notification"].webhook_url, null)
    }

    environment_variable {
      name  = "DISCORD_NOTIFICATION"
      value = tostring(try(each.value["discord-notification"].active, try(each.value["discord-notification"], false), false))
    }

    environment_variable {
      name  = "DISCORD_SECRET_NAME"
      value = try(each.value["discord-notification"].secret_name, null)
    }

    environment_variable {
      name  = "DISCORD_WEBHOOK_URL"
      value = try(each.value["discord-notification"].webhook_url, null)
    }

    environment_variable {
      name  = "SNS_NOTIFICATION"
      value = tostring(try(each.value["sns-notification"].active, try(each.value["sns-notification"], false), false))
    }

    environment_variable {
      name  = "SNS_TOPIC_ARN"
      value = try(each.value["sns-notification"].topic_arn, null)
    }

    environment_variable {
      name  = "ELEMENTARY_CHANNEL"
      value = try(each.value.elementary.channel, null)
    }

    environment_variable {
      name  = "ELEMENTARY_GITPAGES"
      value = tostring(try(each.value.elementary.gitpages, false))
    }

    environment_variable {
      name = "INCIDENT_MANAGER"
      value = tostring(
        lookup(lookup(each.value, "incident-manager", {}), "active", false)
      )
    }

    environment_variable {
      name = "INCIDENT_IMPACT"
      value = tostring(
        lookup(lookup(each.value, "incident-manager", {}), "impact", 1)
      )
    }

    environment_variable {
      name  = "DESCRIPTION_ELEMENTARY"
      value = try(each.value.elementary.description, null)
    }

    environment_variable {
      name  = "PROJECT_NAME"
      value = each.value.name
    }

    environment_variable {
      name  = "ROLE_NAME"
      value = aws_iam_role.codebuild_role[0].arn
    }


    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.aws_account_id
    }

    environment_variable {
      name  = "INCIDENT_RESPONSE_PLAN"
      value = coalesce(
        lookup(each.value, "incident-response-plan", null),
        try(lookup(lookup(each.value, "incident-manager", {}), "incident-response-plan", null), null),
        var.incident_response_plan_default != "" ? var.incident_response_plan_default : null,
        ""
      )
    }

    environment_variable {
      name  = "env"
      value = var.env
    }

    environment_variable {
      name  = "UTC_OFFSET"
      value = tostring(lookup(each.value, "utc", 0))
    }

    environment_variable {
      name  = "AUTO_NOTIFICATIONS"
      value = jsonencode(lookup(each.value, "auto-notifications", []))
    }

    environment_variable {
      name  = "CRITICAL_TABLES"
      value = jsonencode(lookup(each.value, "critical_tables", []))
    }

    environment_variable {
      name  = "NOT_CRITICAL_TABLES"
      value = jsonencode(lookup(each.value, "not_critical_tables", []))
    }

    dynamic "environment_variable" {
      for_each = lookup(each.value, "s3_artifacts_bucket", null) != null ? [1] : []
      content {
        name  = "S3_ARTIFACTS_BUCKET"
        value = lookup(each.value, "s3_artifacts_bucket")
      }
    }

    dynamic "environment_variable" {
      for_each = !var.use_github_native ? [1] : []
      content {
        name  = "GITHUB_SSH_SECRET_ARN"
        value = ""
      }
    }


    dynamic "environment_variable" {
      for_each = lookup(each.value, "secrets_manager_variables", [])
      content {
        name  = keys(environment_variable.value)[0]
        value = values(environment_variable.value)[0]
      }
    }

    dynamic "environment_variable" {
      for_each = lookup(each.value, "environment_variables", {})
      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }
  }
  source_version = var.github_branch
  source {
    type            = var.use_github_native ? "GITHUB" : "NO_SOURCE"
    location        = var.use_github_native ? "https://github.com/${each.value.org}/${each.value.repo}" : null
    git_clone_depth = var.use_github_native ? 1 : null
    buildspec = templatefile("${path.module}/buildspec.tpl", {
      commands                  = each.value.commands
      engine                    = each.value.engine
      elementary_enabled        = try(each.value.elementary.active, each.value.elementary, false)
      slack_notification        = try(each.value["slack-notification"].active, each.value["slack-notification"], false)
      teams_notification        = try(each.value["teams-notification"].active, try(each.value["teams-notification"], false), false)
      discord_notification      = try(each.value["discord-notification"].active, try(each.value["discord-notification"], false), false)
      sns_notification          = try(each.value["sns-notification"].active, try(each.value["sns-notification"], false), false)
      incident_manager          = lookup(each.value, "incident-manager", {})
      slack_channel             = try(each.value["slack-notification"].channel, "")
      description_elementary    = try(each.value.elementary.description, "")
      project_name              = each.value.name
      github_org                = each.value.org
      repo_name                 = each.value.repo
      elementary_gitpages       = try(each.value.elementary.gitpages, false)
      secrets_manager_variables = lookup(each.value, "secrets_manager_variables", [])
      environment_variables     = lookup(each.value, "environment_variables", {})
      use_github_native         = var.use_github_native
      github_branch             = var.github_branch
    })

    dynamic "auth" {

      for_each = var.use_github_native && local.github_connection_available ? [1] : []
      content {
        type     = "CODECONNECTIONS"
        resource = local.github_connection_arn
      }
    }
  }


  dynamic "vpc_config" {
    for_each = lookup(each.value, "vpc_config", null) != null ? [each.value.vpc_config] : []
    content {
      vpc_id             = vpc_config.value.vpc_id
      subnets            = vpc_config.value.subnets
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  tags = merge(var.tags, {
    Name   = each.value.name
    Engine = each.value.engine
  })

  lifecycle {



  }
}

resource "aws_cloudwatch_event_rule" "codebuild_schedule" {
  for_each = { for project in local.scheduled_projects : project.name => project }

  name                = "${var.env}-${each.value.name}-schedule"
  description         = "Schedule for ${each.value.name}"
  schedule_expression = local.process_schedule[each.value.name].final_expression
  state               = "ENABLED"

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "codebuild_target" {
  for_each = { for project in local.scheduled_projects : project.name => project }

  rule      = aws_cloudwatch_event_rule.codebuild_schedule[each.key].name
  target_id = "${var.env}-${each.value.name}-target"
  arn       = aws_codebuild_project.dbt_projects[each.key].arn
  role_arn  = aws_iam_role.events_role[0].arn
}

resource "aws_iam_role" "events_role" {
  count = length(local.scheduled_projects) > 0 ? 1 : 0

  name = "${var.env}-${var.project}-${var.events_role_name_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "events_policy" {
  count = length(local.scheduled_projects) > 0 ? 1 : 0

  role = aws_iam_role.events_role[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codebuild:StartBuild"
        ]
        Resource = [
          for project in aws_codebuild_project.dbt_projects : project.arn
        ]
      }
    ]
  })
}
