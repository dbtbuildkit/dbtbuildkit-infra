<!-- BEGIN_TF_DOCS -->
# Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0.0 |
| external | >= 2.0.0 |
| null | >= 3.0.0 |

# Providers

| Name | Version |
|------|---------|
| aws | >= 4.0.0 |
| external | >= 2.0.0 |
| null | >= 3.0.0 |

# Modules

No modules.

# Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.codebuild_schedule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.codebuild_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_codebuild_project.dbt_projects](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_iam_role.codebuild_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.events_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.codebuild_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.events_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.codebuild_additional_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [null_resource.validate_github_connection](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

# Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_iam\_policy\_arns | List of managed IAM policy ARNs to attach to CodeBuild role. Useful for adding additional permissions without modifying the default policy | `list(string)` | `[]` | no |
| aws\_region | AWS region where resources will be created (e.g.: us-east-1, sa-east-1) | `string` | n/a | yes |
| codebuild\_role\_name\_suffix | Custom suffix for CodeBuild role name. If not provided, uses 'codebuild-role' | `string` | `"codebuild-role"` | no |
| ecr\_dbt | ECR repository name containing the DBT Docker image (without environment prefix) | `string` | `"dbtbuildkit"` | no |
| ecr\_image\_tag | Docker image tag for DBT in ECR | `string` | `"latest"` | no |
| ecr\_image\_uri | Complete URI of the DBT Docker image in ECR. If provided, overrides automatic construction based on ecr\_dbt. Format: <account-id>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag> | `string` | `null` | no |
| ecr\_repository\_arns | List of allowed ECR repository ARNs (used only with use\_minimal\_iam\_policy = true). If empty, allows all repositories | `list(string)` | `[]` | no |
| enable\_default\_iam\_permissions | If true, adds default broad permissions for DBT (S3, Athena, Redshift, Glue, etc). If false, uses only iam\_policy\_statements | `bool` | `true` | no |
| env | Deployment environment (accepted values: dev, stg, prd) | `string` | n/a | yes |
| events\_role\_name\_suffix | Custom suffix for Events role name. If not provided, uses 'events-role' | `string` | `"events-role"` | no |
| file\_name | Configuration file for CodeBuild (dbt\_project.yml or codebuild-config.yml) | `string` | `"dbt_project.yml"` | no |
| github\_branch | GitHub repository branch to use (e.g.: main, develop) | `string` | `"main"` | no |
| github\_connection\_arn | GitHub connection ARN for native integration. Required when use\_github\_native = true | `string` | `null` | no |
| iam\_policy\_statements | List of custom IAM statements to add to CodeBuild policy. If not provided, uses default broad permissions | ```list(object({ Effect = string Action = list(string) Resource = string }))``` | `[]` | no |
| incident\_response\_plan\_default | Default incident response plan name used when not specified in the project | `string` | `""` | no |
| project | Project name for identification and organization of AWS resources | `string` | n/a | yes |
| s3\_buckets | List of allowed S3 buckets for access (used only with use\_minimal\_iam\_policy = true). If empty, allows all buckets | `list(string)` | `[]` | no |
| secrets\_manager\_secrets | List of allowed Secrets Manager secret ARNs (used only with use\_minimal\_iam\_policy = true). If empty, allows all secrets | `list(string)` | `[]` | no |
| tags | Map of common tags applied to all module resources | `map(string)` | n/a | yes |
| use\_github\_native | If true, uses native GitHub integration. If false, uses SSH as fallback. | `bool` | `true` | no |
| use\_minimal\_iam\_policy | If true, uses minimal and restrictive IAM policy. If false, uses broad policy with wildcards. Requires enable\_default\_iam\_permissions = true | `bool` | `false` | no |

# Outputs

| Name | Description |
|------|-------------|
| active\_projects\_summary | Summary of active DBT projects in the environment |
| codebuild\_iam\_role\_arn | ARN of IAM role used by CodeBuild projects |
| codebuild\_projects | List of CodeBuild projects created for DBT execution |
| debug\_schedules | Debug of processed schedule expressions |
| events\_iam\_role\_arn | ARN of IAM role used by CloudWatch Events to schedule executions |
| manual\_projects | List of DBT projects for manual execution |
| scheduled\_projects | List of DBT projects with scheduled execution |
<!-- END_TF_DOCS -->