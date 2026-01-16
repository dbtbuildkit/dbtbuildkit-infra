# Contributing to DbtBuildKit

Thank you for your interest in contributing to DbtBuildKit! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Submitting Changes](#submitting-changes)
- [Review Process](#review-process)

## Code of Conduct

This project adheres to a Code of Conduct that all contributors are expected to follow. Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before contributing.

## Getting Started

### Prerequisites

Before you begin, ensure you have:

- **Terraform** (>= 1.0) installed
- **AWS CLI** configured with appropriate credentials
- **Python** (3.12+) installed (for documentation and scripts)
- **Git** installed and configured
- **Pre-commit hooks** installed (optional but recommended)

### Setting Up Your Development Environment

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/dbtbuildkit-infra.git
   cd dbtbuildkit-infra
   ```

3. **Add the upstream remote**:
   ```bash
   git remote add upstream https://github.com/dbtbuildkit/dbtbuildkit-infra.git
   ```

4. **Install pre-commit hooks** (optional but recommended):
   ```bash
   pip install pre-commit
   pre-commit install
   ```

## Development Workflow

### 1. Create a Branch

Always create a new branch from `main` for your changes:

```bash
git checkout main
git pull upstream main
git checkout -b feature/your-feature-name
```

### Branch Naming Convention

- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions or updates
- `chore/` - Maintenance tasks

### 2. Make Your Changes

- Write clean, maintainable code
- Follow the coding standards (see below)
- Add tests for new functionality
- Update documentation as needed
- Ensure all pre-commit hooks pass

### 3. Test Your Changes

Before submitting, ensure:

- Terraform validates: `terraform validate`
- Terraform formats correctly: `terraform fmt -recursive`
- All tests pass (if applicable)
- Documentation builds successfully: `cd docs && make html`

### 4. Commit Your Changes

Write clear, descriptive commit messages:

```bash
git commit -m "feat: add support for new dbt engine"
```

#### Commit Message Format

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Test additions or changes
- `chore:` - Maintenance tasks
- `perf:` - Performance improvements

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## Coding Standards

### Terraform

- Use **2 spaces** for indentation
- Use **snake_case** for variable and resource names
- Use **descriptive names** for resources
- Add **comments** for complex logic
- Use **variables** instead of hardcoded values
- Follow **Terraform best practices**:
  - Use `terraform fmt` to format code
  - Use `terraform validate` to check syntax
  - Use modules for reusable components
  - Use data sources when appropriate

### Python

- Follow **PEP 8** style guide
- Use **Black** for formatting (line length: 100)
- Use **type hints** where appropriate
- Write **docstrings** for functions and classes
- Maximum line length: **100 characters**

### Shell Scripts

- Use **bash** for scripts
- Add **shebang** (`#!/bin/bash`)
- Add **comments** explaining complex operations
- Use **quotes** around variables
- Check for **errors** and handle them appropriately

### YAML

- Use **2 spaces** for indentation
- Use **descriptive keys**
- Add **comments** where necessary
- Validate YAML syntax before committing

## Testing

### Terraform Testing

1. **Validate syntax**:
   ```bash
   terraform validate
   ```

2. **Format code**:
   ```bash
   terraform fmt -recursive -check
   ```

3. **Plan changes**:
   ```bash
   terraform plan
   ```

### Documentation Testing

Build documentation locally to ensure it renders correctly:

```bash
cd docs
pip install -r requirements.txt
make html
```

Open `docs/_build/html/index.html` in your browser to verify.

## Documentation

### When to Update Documentation

- Adding new features or modules
- Changing existing functionality
- Fixing bugs that affect user experience
- Adding examples or use cases

### Documentation Structure

- **README.md** - Main project documentation
- **docs/** - Detailed documentation (Sphinx)
- **CONTRIBUTING.md** - This file
- **CHANGELOG.md** - Version history

### Writing Documentation

- Use **clear, concise language**
- Include **examples** where helpful
- Add **code blocks** with syntax highlighting
- Keep **up-to-date** with code changes

## Submitting Changes

### Pull Request Checklist

Before submitting a PR, ensure:

- [ ] Code follows project style guidelines
- [ ] All tests pass
- [ ] Documentation is updated
- [ ] Commit messages follow conventions
- [ ] Branch is up to date with `main`
- [ ] No merge conflicts
- [ ] Pre-commit hooks pass (if installed)

### Pull Request Description

Include in your PR description:

- **What** changes were made
- **Why** the changes were necessary
- **How** to test the changes
- **Screenshots** (if UI changes)
- **Related issues** (if any)

### Example PR Description

```markdown
## Description
Adds support for new dbt engine (BigQuery).

## Changes
- Added BigQuery configuration options
- Updated documentation with BigQuery examples
- Added validation for BigQuery-specific settings

## Testing
- [x] Terraform validates successfully
- [x] Tested with example configuration
- [x] Documentation builds correctly

## Related Issues
Closes #123
```

## Review Process

1. **Automated Checks**: GitHub Actions will run automated tests
2. **Code Review**: Maintainers will review your code
3. **Feedback**: Address any requested changes
4. **Approval**: Once approved, your PR will be merged

### Responding to Feedback

- Be **respectful** and **professional**
- **Address** all comments
- **Ask questions** if something is unclear
- **Update** your PR based on feedback

## Questions?

If you have questions or need help:

- Open an **issue** on GitHub
- Start a **discussion** in GitHub Discussions
- Check the **documentation** at [GitHub Pages](https://dbtbuildkit.github.io/dbtbuildkit-infra/)

## Thank You!

Your contributions make DbtBuildKit better for everyone. Thank you for taking the time to contribute! 🎉
