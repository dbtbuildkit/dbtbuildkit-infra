#!/bin/bash
# -*- coding: utf-8 -*-
# Script to build and push Docker image to ECR

set -euo pipefail

FOLDER="${FOLDER}"
TERRAFORM_ROOT="${TERRAFORM_ROOT:-}"
AWS_REGION="${AWS_REGION}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID}"
ECR_REPO_NAME="${ECR_REPO_NAME}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "FOLDER - $FOLDER"
echo "TERRAFORM_ROOT - $TERRAFORM_ROOT"
echo "AWS_REGION - $AWS_REGION"
echo "AWS_ACCOUNT_ID - $AWS_ACCOUNT_ID"
echo "ECR_REPO_NAME - $ECR_REPO_NAME"
echo "IMAGE_TAG - $IMAGE_TAG"

ECR_REPO_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

CURRENT_ARCH=$(uname -m)
case $CURRENT_ARCH in
    x86_64)
        BUILD_PLATFORM="linux/amd64"
        echo "Detected x86_64 architecture - building for linux/amd64"
        ;;
    aarch64|arm64)
        BUILD_PLATFORM="linux/arm64"
        echo "Detected ARM64 architecture - building for linux/arm64"
        ;;
    *)
        BUILD_PLATFORM="linux/amd64"
        echo "Warning: Unknown architecture $CURRENT_ARCH, defaulting to linux/amd64"
        ;;
esac

# Check if FOLDER exists, if not try to find it relative to TERRAFORM_ROOT or Git repository
if [ ! -d "$FOLDER" ]; then
    echo "⚠️  Directory $FOLDER does not exist, trying to find it..."
    
    # First, try to use TERRAFORM_ROOT if provided
    if [ -n "$TERRAFORM_ROOT" ] && [ -d "$TERRAFORM_ROOT" ]; then
        echo "Using TERRAFORM_ROOT as reference: $TERRAFORM_ROOT"
        # Try common paths relative to terraform root
        if [ -d "$TERRAFORM_ROOT/dbtbuildkit/docker" ]; then
            FOLDER="$TERRAFORM_ROOT/dbtbuildkit/docker"
            echo "✅ Found docker directory at: $FOLDER"
        elif [ -d "$TERRAFORM_ROOT/infra/dbtbuildkit/docker" ]; then
            FOLDER="$TERRAFORM_ROOT/infra/dbtbuildkit/docker"
            echo "✅ Found docker directory at: $FOLDER"
        else
            echo "⚠️  Could not find docker directory relative to TERRAFORM_ROOT"
        fi
    fi
    
    # If still not found, try Git repository
    if [ ! -d "$FOLDER" ]; then
        GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
        if [ -n "$GIT_ROOT" ]; then
            echo "Git repository found at: $GIT_ROOT"
            # Try to find docker directory in the Git repository
            if [ -d "$GIT_ROOT/dbtbuildkit/docker" ]; then
                FOLDER="$GIT_ROOT/dbtbuildkit/docker"
                echo "✅ Found docker directory at: $FOLDER"
            elif [ -d "$GIT_ROOT/infra/dbtbuildkit/docker" ]; then
                FOLDER="$GIT_ROOT/infra/dbtbuildkit/docker"
                echo "✅ Found docker directory at: $FOLDER"
            else
                echo "ERROR: Could not find docker directory"
                echo "Searched in:"
                [ -n "$TERRAFORM_ROOT" ] && echo "  - $TERRAFORM_ROOT/dbtbuildkit/docker"
                [ -n "$TERRAFORM_ROOT" ] && echo "  - $TERRAFORM_ROOT/infra/dbtbuildkit/docker"
                echo "  - $GIT_ROOT/dbtbuildkit/docker"
                echo "  - $GIT_ROOT/infra/dbtbuildkit/docker"
                exit 1
            fi
        else
            echo "ERROR: Directory $FOLDER does not exist and could not find Git repository root"
            exit 1
        fi
    fi
fi

# Save the absolute path to the docker folder before changing directories
DOCKER_FOLDER=$(cd "$FOLDER" && pwd) || {
    echo "ERROR: Could not access docker folder: $FOLDER"
    exit 1
}

cd "$DOCKER_FOLDER"
ls -a

echo "Checking Git LFS..."
if command -v git-lfs &> /dev/null; then
    echo "Git LFS is installed"

    GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
    if [ -n "$GIT_ROOT" ]; then
        echo "Git repository found at: $GIT_ROOT"
        cd "$GIT_ROOT"

        if git lfs ls-files | grep -q "dbtbuildkit/docker/dbt-kit" || git lfs ls-files | grep -q "dbt-kit"; then
            echo "Running git lfs pull to download dbt-kit binary..."
            git lfs pull
            echo "✅ Git LFS pull completed"
        else
            echo "ℹ️  dbt-kit file is not tracked by Git LFS or already downloaded"
        fi

        # Return to the docker folder using absolute path
        cd "$DOCKER_FOLDER"
    else
        echo "⚠️  Not a Git repository or could not find root"
    fi
else
    echo "⚠️  Git LFS is not installed. Trying to continue..."
fi

if [ -f "dbt-kit" ]; then
    if head -1 dbt-kit | grep -q "version https://git-lfs"; then
        echo "ERROR: dbt-kit is still a Git LFS pointer!"
        echo "Trying to force Git LFS download..."
        GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
        if [ -n "$GIT_ROOT" ]; then
            cd "$GIT_ROOT"
            git lfs pull --include="dbtbuildkit/docker/dbt-kit" || git lfs pull
            # Return to the docker folder using the saved absolute path
            cd "$DOCKER_FOLDER"

            if head -1 dbt-kit | grep -q "version https://git-lfs"; then
                echo "ERROR: Could not download binary from Git LFS"
                exit 1
            fi
        else
            echo "ERROR: Could not find Git repository root"
            exit 1
        fi
    else
        echo "✅ dbt-kit file is a real binary (not a Git LFS pointer)"
    fi
else
    echo "ERROR: dbt-kit file not found in $FOLDER"
    exit 1
fi

aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo "Building Docker image for platform: $BUILD_PLATFORM"
docker build --platform $BUILD_PLATFORM -t ${ECR_REPO_NAME} .
docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${ECR_REPO_URL}:${IMAGE_TAG}
docker push ${ECR_REPO_URL}:${IMAGE_TAG}

echo "Build and push completed successfully!"
echo "Image built for: $BUILD_PLATFORM"
echo "Image available at: ${ECR_REPO_URL}:${IMAGE_TAG}"
