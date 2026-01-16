<!-- BEGIN_TF_DOCS -->
# Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0.0 |
| null | >= 3.0.0 |

# Providers

| Name | Version |
|------|---------|
| aws | >= 4.0.0 |
| null | >= 3.0.0 |

# Modules

No modules.

# Resources

| Name | Type |
|------|------|
| [aws_codeconnections_connection.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codeconnections_connection) | resource |
| [aws_ecr_lifecycle_policy.delete](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [null_resource.run_script](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.wait_for_github_connection](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

# Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws\_region | AWS region where resources will be created | `string` | n/a | yes |
| connection\_check\_interval\_seconds | Interval (in seconds) between GitHub connection status checks | `number` | `10` | no |
| connection\_wait\_timeout\_minutes | Maximum time (in minutes) to wait for GitHub connection approval | `number` | `30` | no |
| create\_github\_connection | If true, creates a new GitHub connection. If false, uses existing connection (via existing\_github\_connection\_arn) | `bool` | `true` | no |
| ecr\_days\_lifecycle\_policy | Number of images to retain in lifecycle policy | `number` | `5` | no |
| ecr\_image\_tag | Docker image tag in ECR repository | `string` | `"latest"` | no |
| ecr\_image\_tag\_mutability | Image tag mutability in ECR | `string` | `"MUTABLE"` | no |
| ecr\_repository\_name | ECR repository name. If not provided, uses default: {env}-dbtbuildkit | `string` | `null` | no |
| ecr\_repository\_name\_exact | If true, uses exact repository name. If false, adds prefix {env}-{project}- | `bool` | `true` | no |
| ecr\_scan\_on\_push | Enables image scan on push | `bool` | `true` | no |
| env | Deployment environment (accepted values: dev, stg, prd) | `string` | n/a | yes |
| existing\_github\_connection\_arn | ARN of an existing GitHub connection to use. If provided, does not create new connection | `string` | `null` | no |
| github\_organization | GitHub organization (required). Will be used in CodeConnections connection name: {env}-{org}-github-connection. Required for dbt to extract organization name. | `string` | n/a | yes |
| project | Project name for identification and organization of AWS resources | `string` | n/a | yes |
| tags | Map of common tags applied to all module resources | `map(string)` | n/a | yes |
| use\_github\_native | If true, uses native GitHub integration via CodeConnections. If false, uses SSH | `bool` | `true` | no |
| wait\_for\_connection\_approval | If true, waits for manual GitHub connection approval in AWS console before continuing | `bool` | `true` | no |

# Outputs

| Name | Description |
|------|-------------|
| ecr\_repository\_arn | ARN of created ECR repository |
| ecr\_repository\_name | Name of created ECR repository |
| ecr\_repository\_url | ECR repository URL for Docker image push/pull |
| github\_connection\_arn | GitHub connection ARN (created or existing) |
| github\_connection\_id | GitHub connection ID (last part of ARN) |
| github\_connection\_name | GitHub connection name |
| github\_connection\_status | Connection status (PENDING, AVAILABLE, ERROR) |
| github\_connection\_url | URL to complete connection authorization (if status PENDING) |
<!-- END_TF_DOCS -->