# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure
- Documentation setup with Sphinx
- GitHub Actions workflows for CI/CD

## [0.1.0] - 2024-XX-XX

### Added
- Initial release of DbtBuildKit Infrastructure
- `dbtbuildkit` module for ECR and GitHub Connections
- `dbt` module for CodeBuild projects
- Support for multiple dbt engines (Athena, Redshift, BigQuery, Snowflake)
- Automatic Docker image builds
- GitHub integration via AWS CodeConnections
- Multi-environment support (dev, stg, prd)
- CloudWatch Events scheduling
- Multi-channel notifications (Slack, Teams, Discord)
- Elementary Data integration
- Incident management via AWS Systems Manager
- VPC support for private network execution
- Environment variables and AWS Secrets Manager support
- Comprehensive documentation
- Example configurations
- Reusable GitHub Actions workflows for automatic CI/CD setup

### Documentation
- Complete Sphinx documentation
- README with quick start guide
- Usage examples
- CI/CD setup guide

---

## Types of Changes

- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** for vulnerability fixes
