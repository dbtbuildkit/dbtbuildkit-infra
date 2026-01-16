# Security Policy

## Supported Versions

We actively support the following versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |
| < 0.1.0 | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security vulnerability, please follow these steps:

### 1. **Do NOT** create a public GitHub issue

Security vulnerabilities should be reported privately to prevent exploitation.

### 2. Report via Email

Please email security concerns to: **arihenriquedev@hotmail.com**

Include the following information:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)
- Your contact information

### 3. Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Resolution**: Depends on severity and complexity

### 4. Disclosure Policy

- We will acknowledge receipt of your report within 48 hours
- We will keep you informed of our progress
- We will notify you when the vulnerability is fixed
- We will credit you in the security advisory (unless you prefer to remain anonymous)

## Security Best Practices

### For Users

When using DbtBuildKit, please follow these security best practices:

1. **IAM Permissions**: Use the principle of least privilege
   - Grant only necessary permissions to IAM roles
   - Regularly review and audit IAM policies
   - Use separate roles for different environments

2. **Secrets Management**: Never commit secrets to version control
   - Use AWS Secrets Manager for sensitive data
   - Use environment variables for non-sensitive configuration
   - Rotate secrets regularly

3. **Network Security**: Use VPC when possible
   - Enable VPC support for CodeBuild projects
   - Use private subnets for sensitive workloads
   - Configure security groups appropriately

4. **Image Security**: Keep Docker images updated
   - Regularly update base images
   - Scan images for vulnerabilities
   - Use specific image tags (avoid `latest`)

5. **GitHub Connections**: Secure your GitHub integration
   - Use AWS CodeConnections for secure GitHub access
   - Regularly review connection permissions
   - Monitor connection status

6. **Monitoring**: Enable logging and monitoring
   - Enable CloudWatch logs
   - Set up alerts for suspicious activity
   - Review logs regularly

### For Contributors

When contributing to DbtBuildKit:

1. **Code Review**: All code changes require review
2. **Dependencies**: Keep dependencies updated
3. **Testing**: Write tests for security-critical code
4. **Documentation**: Document security considerations

## Known Security Considerations

### AWS Resources

DbtBuildKit creates AWS resources that may have security implications:

- **ECR Repositories**: Store Docker images
- **CodeBuild Projects**: Execute dbt commands
- **IAM Roles**: Grant permissions to resources
- **S3 Buckets**: Store artifacts and state
- **Secrets Manager**: Store sensitive configuration

Ensure you understand the security implications of these resources before deployment.

### Terraform State

Terraform state files may contain sensitive information:

- Use **encrypted S3 buckets** for state storage
- Enable **versioning** on state buckets
- Use **S3 bucket policies** to restrict access
- Consider using **Terraform Cloud** or **Terraform Enterprise** for enhanced security

## Security Updates

Security updates will be released as:
- **Patch versions** (0.1.0 → 0.1.1) for critical security fixes
- **Minor versions** (0.1.0 → 0.2.0) for security improvements
- **Major versions** (0.1.0 → 1.0.0) for breaking security changes

## Security Advisories

Security advisories will be published in:
- GitHub Security Advisories
- CHANGELOG.md under the "Security" section
- Release notes

## Contact

For security-related questions or concerns:
- **Email**: arihenriquedev@hotmail.com
- **GitHub Security**: Use GitHub's security advisory feature

Thank you for helping keep DbtBuildKit secure!
