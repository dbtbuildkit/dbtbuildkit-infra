Usage Examples
==============

This section provides practical examples of how to use the DbtBuildKit modules.

.. note::
   All examples use GitHub as the module source with the format: ``git::https://dbtbuildkit/dbtbuildkit-infra.git//path/to/module``
   
   You can specify a specific version using:
   
   - ``?ref=main`` for the main branch
   - ``?ref=v1.0.0`` for a specific tag
   - ``?ref=abc1234`` for a specific commit
   
   Example: ``git::https://dbtbuildkit/dbtbuildkit-infra.git//dbtbuildkit?ref=v1.0.0``
   
   **Important**: Since modules are called directly from GitHub, they are typically used in separate projects. 
   When using the ``dbt`` module, you should provide the GitHub connection ARN directly instead of referencing 
   outputs from the ``dbtbuildkit`` module. You can find the connection ARN in the AWS Console or from the 
   ``dbtbuildkit`` module outputs if you have access to them.

Basic Setup
-----------

Example 1: Basic DbtBuildKit Module Usage
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This example shows how to create an ECR repository and GitHub connection:

.. code-block:: terraform

   module "dbtbuildkit" {
     source = "git::https://dbtbuildkit/dbtbuildkit-infra.git//dbtbuildkit?ref=main"
     
     project    = "my-project"
     env        = "dev"
     aws_region = "us-east-1"
     
     github_organization = "my-org"
     
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

Example 2: Basic DBT Module Usage
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This example shows how to create DBT CodeBuild projects. Note that the GitHub connection ARN should be provided directly:

.. code-block:: terraform

   module "dbt" {
     source = "git::https://dbtbuildkit/dbtbuildkit-infra.git//dbt?ref=main"
     
     project    = "my-project"
     env        = "dev"
     aws_region = "us-east-1"
     
     # Provide GitHub connection ARN directly
     # You can find this ARN in AWS Console or from dbtbuildkit module outputs
     github_connection_arn = "arn:aws:codeconnections:us-east-1:123456789012:connection/abc123def456"
     
     tags = {
       env     = "dev"
       project = "my-project"
     }
   }

Complete Integration Example
-----------------------------

Example 3: Using Both Modules in Separate Projects
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Since modules are called directly from GitHub, they are typically used in separate Terraform projects. 
Here's how to use them:

**Project 1: Create ECR and GitHub Connection**

.. code-block:: terraform

   module "dbtbuildkit" {
     source = "git::https://dbtbuildkit/dbtbuildkit-infra.git//dbtbuildkit?ref=main"
     
     project             = "my-project"
     env                 = "dev"
     aws_region          = "us-east-1"
     github_organization = "my-org"
     
     # ECR configuration
     ecr_repository_name = "dbtbuildkit-custom"
     ecr_image_tag       = "v1.0.0"
     ecr_scan_on_push    = true
     
     tags = {
       env     = "dev"
       project = "my-project"
     }
   }
   
   # Output the connection ARN for use in other projects
   output "github_connection_arn" {
     value = module.dbtbuildkit.github_connection_arn
   }
   
   output "ecr_repository_url" {
     value = module.dbtbuildkit.ecr_repository_url
   }

**Project 2: Create DBT CodeBuild Projects**

.. code-block:: terraform

   module "dbt" {
     source = "git::https://dbtbuildkit/dbtbuildkit-infra.git//dbt?ref=main"
     
     project    = "my-project"
     env        = "dev"
     aws_region = "us-east-1"
     
     # Provide ARNs directly from Project 1 outputs
     # You can get these values from Project 1's terraform output
     ecr_image_uri         = "123456789012.dkr.ecr.us-east-1.amazonaws.com/dev-dbtbuildkit-custom:v1.0.0"
     github_connection_arn = "arn:aws:codeconnections:us-east-1:123456789012:connection/abc123def456"
     
     tags = {
       env     = "dev"
       project = "my-project"
     }
   }

Advanced Examples
-----------------

Example 4: Using Minimal IAM Policy
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This example shows how to use minimal IAM policy for better security:

.. code-block:: terraform

   module "dbt" {
     source = "git::https://dbtbuildkit/dbtbuildkit-infra.git//dbt?ref=main"
     
     project    = "my-project"
     env        = "dev"
     aws_region = "us-east-1"
     
     # Enable minimal IAM policy
     enable_default_iam_permissions = true
     use_minimal_iam_policy        = true
     
     # Specify allowed resources
     s3_buckets = [
       "my-data-bucket",
       "my-artifacts-bucket"
     ]
     
     secrets_manager_secrets = [
       "arn:aws:secretsmanager:us-east-1:123456789012:secret:my-secret-*"
     ]
     
     ecr_repository_arns = [
       "arn:aws:ecr:us-east-1:123456789012:repository/my-ecr-repo"
     ]
     
     tags = {
       env     = "dev"
       project = "my-project"
     }
   }

Example 5: Custom IAM Policy Statements
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This example shows how to add custom IAM policy statements:

.. code-block:: terraform

   module "dbt" {
     source = "git::https://dbtbuildkit/dbtbuildkit-infra.git//dbt?ref=main"
     
     project    = "my-project"
     env        = "dev"
     aws_region = "us-east-1"
     
     # Disable default permissions and use custom ones
     enable_default_iam_permissions = false
     
     iam_policy_statements = [
       {
         Effect = "Allow"
         Action = [
           "s3:GetObject",
           "s3:PutObject"
         ]
         Resource = "arn:aws:s3:::my-bucket/*"
       },
       {
         Effect = "Allow"
         Action = [
           "secretsmanager:GetSecretValue"
         ]
         Resource = "arn:aws:secretsmanager:us-east-1:*:secret:my-secret-*"
       }
     ]
     
     tags = {
       env     = "dev"
       project = "my-project"
     }
   }

Example 6: Using Existing GitHub Connection
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This example shows how to use an existing GitHub connection:

.. code-block:: terraform

   module "dbtbuildkit" {
     source = "git::https://dbtbuildkit/dbtbuildkit-infra.git//dbtbuildkit?ref=main"
     
     project    = "my-project"
     env        = "dev"
     aws_region = "us-east-1"
     
     # Use existing connection instead of creating new one
     create_github_connection      = false
     existing_github_connection_arn = "arn:aws:codeconnections:us-east-1:123456789012:connection/abc123"
     
     tags = {
       env     = "dev"
       project = "my-project"
     }
   }

Example 7: Custom ECR Repository Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This example shows how to configure a custom ECR repository:

.. code-block:: terraform

   module "dbtbuildkit" {
     source = "git::https://dbtbuildkit/dbtbuildkit-infra.git//dbtbuildkit?ref=main"
     
     project    = "my-project"
     env        = "dev"
     aws_region = "us-east-1"
     
     # Custom ECR configuration
     ecr_repository_name        = "custom-dbt-image"
     ecr_repository_name_exact  = true  # Use exact name without prefix
     ecr_image_tag             = "v2.0.0"
     ecr_image_tag_mutability  = "IMMUTABLE"
     ecr_scan_on_push          = true
     ecr_days_lifecycle_policy = 10
     
     tags = {
       env     = "dev"
       project = "my-project"
     }
   }

Example 8: Using SSH Instead of Native GitHub
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This example shows how to use SSH instead of native GitHub integration:

.. code-block:: terraform

   module "dbt" {
     source = "git::https://dbtbuildkit/dbtbuildkit-infra.git//dbt?ref=main"
     
     project    = "my-project"
     env        = "dev"
     aws_region = "us-east-1"
     
     # Use SSH instead of native GitHub
     use_github_native = false
     
     tags = {
       env     = "dev"
       project = "my-project"
     }
   }

Configuration File Examples
---------------------------

.. warning::
   **Slack Channel Limitation**: Slack channels used for notifications must be public channels. 
   Private channels are not supported and will cause notification failures.

Example 9: Basic codebuild-config.yml
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Create a ``codebuild-config.yml`` file in your project root:

.. code-block:: yaml

   codebuild:
     - name: basic-project
       active: true
       org: my-org
       repo: my-dbt-repo
       engine: redshift
       commands:
         - dbt run
         - dbt test

Example 10: Advanced codebuild-config.yml
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Advanced configuration with notifications and scheduling:

.. code-block:: yaml

   codebuild:
     - name: advanced-project
       active: true
       org: my-org
       repo: my-dbt-repo
       engine: redshift
       commands:
         - dbt run
         - dbt test
         - dbt docs generate
       
       # Schedule execution
       schedule: "cron(0 2 * * ? *)"  # Daily at 2 AM
       
       # Compute configuration
       compute_type: BUILD_GENERAL1_MEDIUM
       timeout: 120
       
       # Slack notifications
       # Note: Slack channels cannot be private channels
       slack-notification:
         active: true
         channel: "#data-ops"  # Must be a public channel
         secret_name: "slack-token"
       
       # Elementary integration
       elementary:
         active: true
         channel: "#elementary-alerts"
         description: "Production DBT project"
         gitpages: true
       
       # Incident management
       incident-manager:
         active: true
         impact: 2
         incident-response-plan: "my-response-plan"
       
       # Critical tables monitoring
       critical_tables:
         - table1
         - table2
       
       # VPC configuration
       vpc_config:
         vpc_id: vpc-12345678
         subnets:
           - subnet-12345678
           - subnet-87654321
         security_group_ids:
           - sg-12345678

Output Usage Examples
---------------------

Example 11: Using Module Outputs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This example shows how to use module outputs. Since modules are typically in separate projects, 
you can access outputs within the same project or reference them from other projects:

**Within the same project:**

.. code-block:: terraform

   module "dbt" {
     source = "git::https://dbtbuildkit/dbtbuildkit-infra.git//dbt?ref=main"
     # ... configuration ...
   }
   
   # Access CodeBuild projects
   output "codebuild_projects" {
     value = module.dbt.codebuild_projects
   }
   
   # Access scheduled projects
   output "scheduled_projects" {
     value = module.dbt.scheduled_projects
   }
   
   # Use in other resources within the same project
   resource "aws_cloudwatch_dashboard" "dbt_dashboard" {
     dashboard_name = "dbt-projects"
     
     dashboard_body = jsonencode({
       widgets = [
         {
           type   = "metric"
           properties = {
             metrics = [
               ["AWS/CodeBuild", "BuildDuration", { "ProjectName" = "project-name" }]
             ]
           }
         }
       ]
     })
   }
   
   # Example: Iterate over projects (simplified)
   # You can use for expressions to create metrics for each project:
   # metrics = [for name, project in module.dbt.codebuild_projects : 
   #   ["AWS/CodeBuild", "BuildDuration", { "ProjectName" = project.name }]
   # ]

**From another project (using remote state or manual values):**

If you need to reference outputs from the ``dbtbuildkit`` module in another project, you can:

1. Use Terraform remote state to read outputs
2. Manually provide the ARN/URL values (recommended for simplicity)
3. Use AWS Console to find the connection ARN

Example with manual values:

.. code-block:: terraform

   module "dbt" {
     source = "git::https://dbtbuildkit/dbtbuildkit-infra.git//dbt?ref=main"
     
     project    = "my-project"
     env        = "dev"
     aws_region = "us-east-1"
     
     # Provide ECR URI and GitHub connection ARN directly
      ecr_image_uri         = "123456789012.dkr.ecr.us-east-1.amazonaws.com/dev-dbtbuildkit:latest"
      github_connection_arn = "arn:aws:codeconnections:us-east-1:123456789012:connection/abc123def456"
      
      tags = {
        env     = "dev"
        project = "my-project"
      }
    }

Navigation
----------

* :doc:`index` - Home
* :doc:`quickstart` - Quick Start Guide
* :doc:`examples` - Usage Examples
* :doc:`modules/dbt` - Module DBT
* :doc:`modules/dbtbuildkit` - Module DbtBuildKit
* :doc:`cicd` - CI/CD Setup Guide