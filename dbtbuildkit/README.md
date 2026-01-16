# DbtBuildKit AWS Module

This Terraform module automatically integrates ECR repository creation and GitHub connection, facilitating DbtBuildKit usage on AWS. **All logic is integrated in this module**, there are no external module dependencies.

## Features

- ✅ Automatically creates ECR repository and builds Docker image
- ✅ Automatically creates GitHub connection via AWS CodeConnections
- ✅ The `src` folder is included in the module, no need to manage separately
- ✅ **Self-contained module** - all logic integrated, no external dependencies
- ✅ Configurable through variables

## Structure

```
dbtbuildkit/
├── main.tf           # Main module configuration (ECR + GitHub Connection integrated)
├── variables.tf      # Module variables
├── outputs.tf        # Module outputs
├── README.md         # This documentation
├── scripts/          # Docker build scripts
│   ├── script.sh     # Image build and push script
│   └── list_files.sh # Script to list monitored files
└── src/              # DbtBuildKit source code
    ├── dbt_buildkit/
    ├── dbt_buildkit_cli.py
    ├── Dockerfile
    └── pyproject.toml
```

## Usage

### Basic Example

```hcl
module "dbtbuildkit" {
  source = "./modules/dbtbuildkit"
  
  project    = "my-project"
  env        = "dev"
  aws_region = "us-east-1"
  tags = {
    env              = "dev"
    project          = "my-project"
    author           = "John Doe"
    creation_date    = "2024-01-01"
    owner            = "john.doe@example.com"
    data_sensitivity = "Confidential"
    purpose          = "ETL_Process"
    department       = "Operations"
    cost_center      = "DataOps"
    version          = "v1.0"
  }
}
```

### Complete Example

```hcl
module "dbtbuildkit" {
  source = "./modules/dbtbuildkit"
  
  # Required variables
  project    = "my-project"
  env        = "dev"
  aws_region = "us-east-1"
  tags = {
    env              = "dev"
    project          = "my-project"
    author           = "John Doe"
    creation_date    = "2024-01-01"
    owner            = "john.doe@example.com"
    data_sensitivity = "Confidential"
    purpose          = "ETL_Process"
    department       = "Operations"
    cost_center      = "DataOps"
    version          = "v1.0"
  }
  
  # GitHub configuration
  use_github_native        = true
  create_github_connection = true
  github_organization      = "my-org"
  
  # ECR configuration
  ecr_repository_name = "dbtbuildkit-custom"
  ecr_image_tag       = "v1.0.0"
  ecr_scan_on_push    = true
}
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Output Usage Example

```hcl
module "dbtbuildkit" {
  source = "./modules/dbtbuildkit"
  # ... configuration ...
}

# Use ECR URL in another resource
resource "aws_codebuild_project" "example" {
  # ...
  environment {
    image = module.dbtbuildkit.ecr_repository_url
  }
}

# Use GitHub connection ARN
resource "aws_codebuild_source_credential" "example" {
  # ...
  token = module.dbtbuildkit.github_connection_arn
}
```

## Important Notes

1. **Self-Contained Module**: This module integrates all ECR and GitHub Connection logic. There's no need to use the `ecr` or `github-connection` modules separately.

2. **src folder**: The `src` folder is included in the module and doesn't need to be managed separately. The Docker image build automatically uses files from this folder.

3. **GitHub Connection**: After creating the connection, you need to authorize it in the AWS console. The `github_connection_url` output provides the direct link when status is `PENDING`.

4. **Image Build**: The Docker image is built automatically when there are changes in monitored files (`ecr_files` and files inside `ecr_watch_folder`). The build automatically detects architecture (x86_64 or ARM64).

5. **Scripts**: The `script.sh` and `list_files.sh` scripts are included in the module in `scripts/` and are automatically executed by Terraform.

## Requirements

- Terraform >= 1.0.0
- AWS Provider >= 4.0.0
- Docker (for image build)
- AWS CLI configured
