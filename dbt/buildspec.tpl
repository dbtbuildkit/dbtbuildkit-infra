version: 0.2

%{ if !use_github_native || length(secrets_manager_variables) > 0 ~}
env:
%{ if !use_github_native ~}
  secrets-manager:
    GITHUB_SSH_KEY: $GITHUB_SSH_SECRET_ARN
%{ if length(secrets_manager_variables) > 0 ~}
%{ for secret_config in secrets_manager_variables ~}
%{ for env_var, secret_arn in secret_config ~}
    ${env_var}: $${secret_arn}
%{ endfor ~}
%{ endfor ~}
%{ endif ~}
%{ else ~}
%{ if length(secrets_manager_variables) > 0 ~}
  secrets-manager:
%{ for secret_config in secrets_manager_variables ~}
%{ for env_var, secret_arn in secret_config ~}
    ${env_var}: $${secret_arn}
%{ endfor ~}
%{ endfor ~}
%{ endif ~}
%{ endif ~}
%{ endif ~}

phases:
  install:
    commands:
      - echo "Using pre-configured ECR image, skipping package installation"

  pre_build:
    commands:
      - export NO_COLOR=1
      - export TERM=dumb
%{ for env_var, env_value in environment_variables ~}
      - export ${env_var}="${env_value}"
%{ endfor ~}
%{ if use_github_native ~}
      - cp -rf /usr/src/app/* ./
%{ else ~}
      - mkdir -p ~/.ssh
      - chmod 700 ~/.ssh
      - echo "$GITHUB_SSH_KEY" > ~/.ssh/id_rsa
      - chmod 600 ~/.ssh/id_rsa
      - ssh-keyscan github.com >> ~/.ssh/known_hosts
      - chmod 644 ~/.ssh/known_hosts
      - git clone -b ${github_branch} git@github.com:${github_org}/${repo_name}.git .
      - cp -rf /usr/src/app/* ./
%{ endif ~}
      - 'which dbt-kit || (echo "ERROR: dbt-kit not found in PATH" && exit 1)'
      - dbt-kit cred --region $AWS_DEFAULT_REGION
      - dbt deps

  build:
    commands:
      - 'which dbt-kit || (echo "ERROR: dbt-kit not found in PATH" && exit 1)'
      - dbt-kit execute-commands
%{ for cmd in commands ~}
      - ${cmd}
%{ endfor ~}

  post_build:
    commands:
      - export GITHUB_ORG="${github_org}"
      - export REPO_NAME="${repo_name}"
      - export ELEMENTARY_GITPAGES="${elementary_gitpages}"
      - 'which dbt-kit || (echo "ERROR: dbt-kit not found in PATH" && exit 1)'
      - dbt-kit post-build

artifacts:
  files:
    - '**/*'
  base-directory: '.'
