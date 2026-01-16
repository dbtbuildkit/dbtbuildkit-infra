DBT Module
==========

This module manages CodeBuild projects for DBT pipeline execution.

Resources
---------

The module creates the following AWS resources:

* **aws_iam_role.codebuild_role**: IAM role for CodeBuild
* **aws_iam_role_policy.codebuild_policy**: IAM policy for CodeBuild
* **aws_codebuild_project.dbt_projects**: CodeBuild projects for each configured DBT project
* **aws_cloudwatch_event_rule.codebuild_schedule**: Scheduling rules for projects with schedule
* **aws_cloudwatch_event_target.codebuild_target**: Targets for scheduling rules
* **aws_iam_role.events_role**: IAM role for CloudWatch Events

Inputs
------

.. include:: ../_generated/dbt_inputs.rst

Outputs
-------

.. include:: ../_generated/dbt_outputs.rst

Examples
--------

See the :doc:`../examples` section for practical usage examples.

Navigation
----------

* :doc:`../index` - Home
* :doc:`../quickstart` - Quick Start Guide
* :doc:`../examples` - Usage Examples
* :doc:`dbtbuildkit` - DbtBuildKit Module
* :doc:`../cicd` - CI/CD Setup Guide
