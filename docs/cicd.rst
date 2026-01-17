CI/CD Setup
===========

DbtBuildKit includes reusable GitHub Actions workflows that automatically configure all CI/CD infrastructure. This feature eliminates the need to manually configure S3 buckets, IAM roles, and OIDC providers.

Overview
--------

The CI/CD setup consists of three reusable workflows that can be called from any GitHub repository:

1. **setup-cicd.yml**: Automatically sets up CI/CD infrastructure (S3, IAM, OIDC)
2. **ci.yml**: Runs Terraform plan for review
3. **cd.yml**: Runs Terraform apply to provision infrastructure

How It Works
------------

1. **Initial Setup**: The ``setup-cicd.yml`` workflow checks if infrastructure exists and creates it if needed
2. **Reusable Workflows**: The ``ci.yml`` and ``cd.yml`` workflows can be used in your CI/CD pipelines
3. **Secure Authentication**: Uses OIDC for GitHub → AWS authentication (no permanent credentials needed)

Quick Start
-----------

Step 1: Configure GitHub Secrets
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Go to **Settings > Secrets and variables > Actions** in your repository and add:

**Required Secrets:**
- ``AWS_ACCOUNT_ID``: AWS Account ID (REQUIRED for all workflows)
- ``AWS_ACCESS_KEY_ID``: AWS Access Key ID (REQUIRED for setup-cicd.yml)
- ``AWS_SECRET_ACCESS_KEY``: AWS Secret Access Key (REQUIRED for setup-cicd.yml)

**Optional Secrets (for setup-cicd.yml):**
- ``AWS_POLICY_ARN``: ARN of custom IAM policy to attach to the created role (optional, uses default policy if not provided)
- ``AWS_SECRET_TOKEN``: AWS Session Token (optional, required for SSO/temporary credentials)

**Note:** 
- If ``AWS_POLICY_ARN`` is not provided, a default policy optimized for dbt projects CI/CD will be automatically created
- If you're using SSO/temporary credentials, you must also provide ``AWS_SECRET_TOKEN`` along with ``AWS_ACCESS_KEY_ID`` and ``AWS_SECRET_ACCESS_KEY``

Step 2: Create Your CI/CD Workflow
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
         AWS_SECRET_TOKEN: ${{ secrets.AWS_SECRET_TOKEN }}
         AWS_POLICY_ARN: ${{ secrets.AWS_POLICY_ARN }}

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

**Note:** Replace ``dbtbuildkit/dbtbuildkit-infra`` with your DbtBuildKit repository path.

Available Workflows
-------------------

setup-cicd.yml
~~~~~~~~~~~~~~

Automatically checks if CI/CD infrastructure exists and creates it if needed.

**Inputs:**

- ``environment`` (optional): Environment (dev, stg, prd) - default: 'dev'
- ``aws_region`` (optional): AWS region - default: 'us-east-1'

**Secrets:**

- ``AWS_ACCOUNT_ID`` (required): AWS Account ID
- ``AWS_ACCESS_KEY_ID`` (required): AWS Access Key ID
- ``AWS_SECRET_ACCESS_KEY`` (required): AWS Secret Access Key
- ``AWS_SECRET_TOKEN`` (optional): AWS Session Token (required for SSO/temporary credentials)
- ``AWS_POLICY_ARN`` (optional): ARN of custom IAM policy to attach to the created role (uses default policy if not provided)

**Outputs:**

- ``role_arn``: ARN of the created IAM role

**What it creates:**

- S3 bucket for Terraform state (with versioning enabled) following the pattern: ``{environment}-{region}-{aws_account_id}--tfstates``
- IAM Role for GitHub Actions following the pattern: ``github-actions-role-{aws_account_id}-{region}``
- IAM Policy (default policy optimized for dbt projects CI/CD, or custom policy if ``AWS_POLICY_ARN`` is provided)
- OIDC Provider for GitHub authentication

ci.yml
~~~~~~

Runs ``terraform plan`` for review. Can comment on Pull Requests with the plan output.

**Inputs:**

- ``environment`` (required): Environment (dev, stg, prd)
- ``aws_region`` (optional): AWS region - default: 'us-east-1'
- ``terraform_directory`` (optional): Directory containing Terraform files - default: '.'
- ``terraform_version`` (optional): Terraform version - default: '1.6.0'

**Secrets:**

- ``AWS_ACCOUNT_ID`` (required): AWS Account ID (used to construct the IAM role ARN following the pattern: ``github-actions-role-${AWS_ACCOUNT_ID}-${AWS_REGION}``)

**Features:**

- Generates Terraform plan
- Uploads plan as artifact
- Comments on Pull Requests (if triggered by PR)

cd.yml
~~~~~~

Runs ``terraform apply`` to provision or update infrastructure.

**Inputs:**

- ``environment`` (required): Environment (dev, stg, prd)
- ``aws_region`` (optional): AWS region - default: 'us-east-1'
- ``terraform_directory`` (optional): Directory containing Terraform files - default: '.'
- ``terraform_version`` (optional): Terraform version - default: '1.6.0'
- ``auto_approve`` (optional): Auto approve apply - default: false

**Secrets:**

- ``AWS_ACCOUNT_ID`` (required): AWS Account ID (used to construct the IAM role ARN following the pattern: ``github-actions-role-${AWS_ACCOUNT_ID}-${AWS_REGION}``)

**Features:**

- Downloads plan artifact (if available)
- Applies Terraform changes
- Supports auto-approval for automated deployments

State Management
----------------

The workflows automatically configure Terraform state management:

- **S3 Backend**: State is stored in S3 bucket
- **State Locking**: Uses S3 lockfile (``use_lockfile = true``)
- **Encryption**: State files are encrypted at rest
- **Versioning**: S3 bucket versioning is enabled for state recovery

The bucket name follows the pattern: ``{environment}-{region}-{aws_account_id}--tfstates``

State key follows the pattern: ``{repo-owner}/{repo-name}/terraform.tfstate``

The IAM role ARN is constructed using: ``arn:aws:iam::{aws_account_id}:role/github-actions-role-{aws_account_id}-{region}``

Multi-Environment Support
--------------------------

You can use different environments (dev, stg, prd) by passing the ``environment`` input:

.. code-block:: yaml

   jobs:
     setup-dev:
       uses: dbtbuildkit/dbtbuildkit-infra/.github/workflows/setup-cicd.yml@main
       with:
         environment: 'dev'
         aws_region: 'us-east-1'

     setup-stg:
       uses: dbtbuildkit/dbtbuildkit-infra/.github/workflows/setup-cicd.yml@main
       with:
         environment: 'stg'
         aws_region: 'us-east-1'

Each environment will have its own:
- S3 bucket for Terraform state (following the pattern: ``{environment}-{region}-{aws_account_id}--tfstates``)
- IAM Role (shared across environments in the same region, following the pattern: ``github-actions-role-{aws_account_id}-{region}``)
- The provided IAM Policy is attached to the role

AWS Region Support
------------------

All workflows support choosing the AWS region through the ``aws_region`` parameter:

.. code-block:: yaml

   jobs:
     setup:
       uses: dbtbuildkit/dbtbuildkit-infra/.github/workflows/setup-cicd.yml@main
       with:
         environment: 'dev'
         aws_region: 'sa-east-1'  # São Paulo

The chosen region will be used to create all AWS resources (S3, IAM, etc.).

Security
--------

- **OIDC Authentication**: Uses OpenID Connect for secure GitHub → AWS authentication
- **No Permanent Credentials**: No need to store AWS access keys in GitHub secrets
- **Least Privilege**: IAM policies are scoped to necessary permissions
- **State Encryption**: Terraform state files are encrypted at rest
- **Versioning**: S3 bucket versioning enabled for state recovery

IAM Permissions
~~~~~~~~~~~~~~~

The default IAM policy includes permissions for:

- Terraform state management (S3)
- CodeBuild management
- CodeConnections management
- ECR management
- IAM management (limited)
- CloudWatch Logs
- Secrets Manager
- Data engines (Athena, Glue, Redshift, Lake Formation)
- S3 artifacts
- SSM Parameter Store

You can optionally provide a custom IAM policy ARN via the ``AWS_POLICY_ARN`` secret. If not provided, a default policy optimized for dbt projects CI/CD will be automatically created.

Examples
--------

Basic Example
~~~~~~~~~~~~~

Simple CI/CD pipeline with plan and apply:

.. code-block:: yaml

   name: CI/CD

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
       secrets:
         AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}
         AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
         AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
         AWS_POLICY_ARN: ${{ secrets.AWS_POLICY_ARN }}

     ci:
       needs: setup-cicd
       uses: dbtbuildkit/dbtbuildkit-infra/.github/workflows/ci.yml@main
       with:
         environment: 'dev'
       secrets:
         AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}

     cd:
       needs: [setup-cicd, ci]
       if: github.ref == 'refs/heads/main'
       uses: dbtbuildkit/dbtbuildkit-infra/.github/workflows/cd.yml@main
       with:
         environment: 'dev'
         auto_approve: true
       secrets:
         AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}

Multi-Environment Example
~~~~~~~~~~~~~~~~~~~~~~~~~

Using different environments:

.. code-block:: yaml

   jobs:
     setup-dev:
       uses: dbtbuildkit/dbtbuildkit-infra/.github/workflows/setup-cicd.yml@main
       with:
         environment: 'dev'
         aws_region: 'us-east-1'
       secrets:
         AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}
         AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
         AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
         AWS_POLICY_ARN: ${{ secrets.AWS_POLICY_ARN }}

     ci-dev:
       needs: setup-dev
       uses: dbtbuildkit/dbtbuildkit-infra/.github/workflows/ci.yml@main
       with:
         environment: 'dev'
         aws_region: 'us-east-1'
       secrets:
         AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}

     setup-prod:
       uses: dbtbuildkit/dbtbuildkit-infra/.github/workflows/setup-cicd.yml@main
       with:
         environment: 'prd'
         aws_region: 'us-east-1'
       secrets:
         AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}
         AWS_POLICY_ARN: ${{ secrets.AWS_POLICY_ARN }}

     cd-prod:
       needs: setup-prod
       uses: dbtbuildkit/dbtbuildkit-infra/.github/workflows/cd.yml@main
       with:
         environment: 'prd'
         aws_region: 'us-east-1'
         auto_approve: true
       secrets:
         AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}

Terraform in Subdirectory
~~~~~~~~~~~~~~~~~~~~~~~~~~

If your Terraform files are in a subdirectory:

.. code-block:: yaml

   jobs:
     ci:
       uses: dbtbuildkit/dbtbuildkit-infra/.github/workflows/ci.yml@main
       with:
         environment: 'dev'
         terraform_directory: 'terraform'
       secrets:
         AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}

Troubleshooting
---------------

Workflow Not Found
~~~~~~~~~~~~~~~~~~

If you see "Unable to find reusable workflow" errors:

1. Make sure you've replaced ``OWNER/REPO`` with the actual DbtBuildKit repository path
2. Verify the branch/tag exists (e.g., ``@main``)
3. Check that the workflow file exists in the repository

Authentication Errors
~~~~~~~~~~~~~~~~~~~~~

If you see AWS authentication errors:

1. Verify ``AWS_ACCOUNT_ID`` and ``AWS_POLICY_ARN`` secrets are configured correctly
2. Check that the IAM role (following the pattern ``github-actions-role-{aws_account_id}-{region}``) has the necessary trust relationship with GitHub OIDC
3. If using SSO/OIDC, ensure your GitHub Actions environment has proper AWS credentials configured
4. If using access keys, verify ``AWS_ACCESS_KEY_ID`` and ``AWS_SECRET_ACCESS_KEY`` are correct

State Lock Errors
~~~~~~~~~~~~~~~~~

If you see state lock errors:

1. Check if another Terraform operation is running
2. Verify S3 bucket permissions
3. Check if lockfile exists in S3 and remove if stale

More Information
----------------

- **Example Workflow**: See ``.github/workflows/example-user-workflow.yml`` for a complete example
- **GitHub Actions Docs**: `Reusable Workflows <https://docs.github.com/en/actions/using-workflows/reusing-workflows>`_

Navigation
----------

* :doc:`index` - Home
* :doc:`quickstart` - Quick Start Guide
* :doc:`examples` - Usage Examples
* :doc:`modules/dbt` - DBT Module
* :doc:`modules/dbtbuildkit` - DbtBuildKit Module
