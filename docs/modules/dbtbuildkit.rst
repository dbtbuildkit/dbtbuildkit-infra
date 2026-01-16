DbtBuildKit Module
===================

This module manages the ECR repository and GitHub connections via AWS CodeConnections.

Resources
---------

The module creates the following AWS resources:

* **aws_ecr_repository.this**: ECR repository to store Docker images
* **aws_ecr_lifecycle_policy.delete**: ECR lifecycle policy
* **aws_codeconnections_connection.github**: GitHub connection via CodeConnections (optional)

Inputs
------

.. include:: ../_generated/dbtbuildkit_inputs.rst

Outputs
-------

.. include:: ../_generated/dbtbuildkit_outputs.rst

Examples
--------

See the :doc:`../examples` section for practical usage examples.

Navigation
----------

* :doc:`../index` - Home
* :doc:`../quickstart` - Quick Start Guide
* :doc:`../examples` - Usage Examples
* :doc:`dbt` - DBT Module
* :doc:`../cicd` - CI/CD Setup Guide
