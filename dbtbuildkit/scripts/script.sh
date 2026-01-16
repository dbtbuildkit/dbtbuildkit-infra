#!/bin/bash
# -*- coding: utf-8 -*-
# Script to build and push Docker image to ECR

set -euo pipefail

FOLDER="${FOLDER}"
AWS_REGION="${AWS_REGION}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID}"
ECR_REPO_NAME="${ECR_REPO_NAME}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "FOLDER - $FOLDER"
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

cd "$FOLDER"
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

        cd "$FOLDER"
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
            cd "$FOLDER"

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
