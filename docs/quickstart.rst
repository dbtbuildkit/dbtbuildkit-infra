Quick Start Guide
==================

Welcome to DbtBuildKit! This guide will help you get started quickly with setting up your dbt infrastructure on AWS.

What is DbtBuildKit?
--------------------

**DbtBuildKit** is a Terraform-based infrastructure solution that automatically provisions all necessary AWS resources for running dbt projects. It eliminates the complexity of manually configuring:

- ECR repositories for Docker images
- GitHub connections via AWS CodeConnections
- CodeBuild projects for dbt execution
- CI/CD pipelines
- IAM roles and permissions
- CloudWatch scheduling
- Notifications (Slack, Teams, Discord)

With DbtBuildKit, you can focus 100% on developing and maintaining your dbt projects while the infrastructure is managed automatically.

Prerequisites
-------------

Before you begin, ensure you have:

* **AWS Account** with appropriate permissions
* **Terraform** installed (version >= 1.0)
* **AWS CLI** configured with valid credentials
* **GitHub access** (organization or repositories)
* **Basic knowledge** of Terraform and dbt (recommended)

Required AWS Permissions
~~~~~~~~~~~~~~~~~~~~~~~~

The user/role running Terraform needs permissions for:

* ECR (create repositories, push/pull images)
* CodeBuild (create projects, roles, policies)
* CodeConnections (create GitHub connections)
* IAM (create roles and policies)
* CloudWatch Events (create scheduling rules)
* S3 (create buckets for artifacts)
* Secrets Manager (if using secrets)

Installation
------------

Option 1: Automatic CI/CD Setup (Recommended)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The fastest way to get started is using the automatic CI/CD setup with GitHub Actions.

Step 1: Configure GitHub Secrets
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Go to your repository **Settings > Secrets and variables > Actions** and add:

**Required Secrets:**

* ``AWS_ACCOUNT_ID``: Your AWS Account ID
* ``AWS_ACCESS_KEY_ID``: AWS Access Key ID (for initial setup)
* ``AWS_SECRET_ACCESS_KEY``: AWS Secret Access Key (for initial setup)

**Optional Secrets:**

* ``AWS_POLICY_ARN``: ARN of custom IAM policy (uses default if not provided)
* ``AWS_SECRET_TOKEN``: AWS Session Token (required for SSO/temporary credentials)

Step 2: Create CI/CD Workflow
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Create a ``.github/workflows/cicd.yml`` file in your repository:

.. code-block:: yaml

   name: CI/CD Pipeline

   on:
     push:
       branches: [main]
     pull_request:
       branches: [main]

   jobs:
     setup-cicd:
       uses: dbtbuildkit/dbtbuildkit-infra/.github/workflows/setup-cicd.yml@main
       with:
         environment: 'dev'
         aws_region: 'us-east-1'
       secrets:
         AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}
         AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
         AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

     ci:
       needs: setup-cicd
       uses: dbtbuildkit/dbtbuildkit-infra/.github/workflows/ci.yml@main
       with:
         environment: 'dev'
         aws_region: 'us-east-1'
       secrets:
         AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}

     cd:
       needs: [setup-cicd, ci]
       if: github.ref == 'refs/heads/main'
       uses: dbtbuildkit/dbtbuildkit-infra/.github/workflows/cd.yml@main
       with:
         environment: 'dev'
         aws_region: 'us-east-1'
         auto_approve: true
       secrets:
         AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}

The workflow will automatically:

* Check if infrastructure exists
* Create S3 bucket for Terraform state (if needed)
* Create IAM Role for GitHub Actions
* Create OIDC Provider for authentication (if needed)

Option 2: Manual Setup
~~~~~~~~~~~~~~~~~~~~~~~

If you prefer to set up manually:

Step 1: Clone the Repository
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   git clone https://github.com/dbtbuildkit/dbtbuildkit-infra.git
   cd dbtbuildkit-infra

Step 2: Configure Terraform Backend
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Create a ``backend.tf`` file:

.. code-block:: terraform

   terraform {
     backend "s3" {
       bucket = "your-terraform-state-bucket"
       key    = "dbtbuildkit/terraform.tfstate"
       region = "us-east-1"
     }
   }

Step 3: Configure Variables
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Create a ``terraform.tfvars`` file:

.. code-block:: hcl

   aws_region        = "us-east-1"
   env               = "dev"
   project           = "my-project"
   github_organization = "my-org"

   tags = {
     env              = "dev"
     project          = "my-project"
     owner            = "data-team@example.com"
     data_sensitivity = "Internal"
     purpose          = "ETL_Process"
   }

Step 4: Use the Modules
^^^^^^^^^^^^^^^^^^^^^^^

Create a ``main.tf`` file:

.. code-block:: terraform

   # Module to create ECR and GitHub Connection
   module "dbtbuildkit" {
     source = "git::https://github.com/dbtbuildkit/dbtbuildkit-infra.git//dbtbuildkit?ref=main"
     
     project            = var.project
     env                = var.env
     aws_region         = var.aws_region
     github_organization = var.github_organization
     tags               = var.tags
   }

   # Module to create CodeBuild projects
   module "dbt_projects" {
     source = "git::https://github.com/dbtbuildkit/dbtbuildkit-infra.git//dbt?ref=main"
     
     project              = var.project
     env                  = var.env
     aws_region           = var.aws_region
     github_connection_arn = module.dbtbuildkit.github_connection_arn
     tags                 = var.tags
     
     depends_on = [module.dbtbuildkit]
   }

Step 5: Configure dbt Projects
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Create a ``codebuild-config.yml`` file:

.. code-block:: yaml

   codebuild:
     - name: my-dbt-project
       active: true
       org: my-org
       repo: my-dbt-repo
       engine: athena
       commands:
         - dbt deps
         - dbt build
       s3_artifacts_bucket: "my-artifacts-bucket"

Step 6: Apply Infrastructure
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   terraform init
   terraform plan
   terraform apply

.. note::
   If using ``wait_for_connection_approval = true``, you will need to approve the GitHub connection in the AWS console before Terraform continues.

Your First dbt Project
----------------------

After setting up the infrastructure, you can configure your first dbt project.

Basic Configuration
~~~~~~~~~~~~~~~~~~~

Create a ``codebuild-config.yml`` file in your repository root:

.. code-block:: yaml

   codebuild:
     - name: my-first-dbt-project
       active: true
       org: my-github-org
       repo: my-dbt-repo
       engine: athena
       commands:
         - dbt deps
         - dbt build
       s3_artifacts_bucket: "my-artifacts-bucket"

Configuration Options
~~~~~~~~~~~~~~~~~~~~~

* **name**: Unique name for your CodeBuild project
* **active**: Set to ``true`` to enable the project
* **org**: GitHub organization name
* **repo**: GitHub repository name
* **engine**: dbt adapter (athena, redshift, snowflake, bigquery, etc.)
* **commands**: List of dbt commands to execute
* **s3_artifacts_bucket**: S3 bucket for storing build artifacts

Scheduled Execution
~~~~~~~~~~~~~~~~~~~

To schedule automatic execution, add a schedule:

.. code-block:: yaml

   codebuild:
     - name: scheduled-project
       active: true
       org: my-org
       repo: my-dbt-repo
       engine: redshift
       commands:
         - dbt run --select tag:daily
         - dbt test
       schedule: "cron(0 2 * * ? *)"  # Daily at 2 AM UTC
       timeout: 120

Notifications
~~~~~~~~~~~~~

Configure Slack notifications:

.. code-block:: yaml

   codebuild:
     - name: project-with-notifications
       active: true
       org: my-org
       repo: my-dbt-repo
       engine: redshift
       commands:
         - dbt run
         - dbt test
       
       slack-notification:
         active: true
         channel: "#data-alerts"  # Must be a public channel
         secret_name: "slack-token"

.. warning::
   Slack channels used for notifications must be **public channels**. Private channels are not supported.

Next Steps
----------

Now that you have the basics set up, explore:

* :doc:`examples` - More configuration examples
* :doc:`modules/dbt` - Complete DBT module documentation
* :doc:`modules/dbtbuildkit` - Complete DbtBuildKit module documentation
* :doc:`variables` - All available variables
* :doc:`outputs` - Module outputs reference
* :doc:`cicd` - Advanced CI/CD configuration

Common Issues
-------------

GitHub Connection Approval
~~~~~~~~~~~~~~~~~~~~~~~~~~

If you're using ``wait_for_connection_approval = true``, you need to approve the connection in AWS Console:

1. Go to AWS CodeConnections console
2. Find your connection (it will be in "Pending" status)
3. Click "Approve connection"

IAM Permissions
~~~~~~~~~~~~~~~

If you encounter permission errors, ensure your AWS credentials have the required permissions listed in the Prerequisites section.

Terraform State
~~~~~~~~~~~~~~~

Make sure your Terraform backend is properly configured. The state file should be stored in S3 for team collaboration.

Getting Help
------------

* **Documentation**: See the full documentation in :doc:`index`
* **Issues**: Report issues on `GitHub Issues <https://github.com/dbtbuildkit/dbtbuildkit-infra/issues>`_
* **Discussions**: Ask questions on `GitHub Discussions <https://github.com/dbtbuildkit/dbtbuildkit-infra/discussions>`_

Navigation
----------

* :doc:`index` - Home
* :doc:`examples` - Usage Examples
* :doc:`modules/dbt` - DBT Module
* :doc:`modules/dbtbuildkit` - DbtBuildKit Module
* :doc:`cicd` - CI/CD Setup Guide
