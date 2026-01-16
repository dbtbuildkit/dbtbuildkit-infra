#!/bin/bash
set -e

# Script to validate if the GitHub connection via CodeConnections is available
# Usage: validate_github_connection.sh <connection_arn> <aws_region>

CONN_ARN="${1}"
AWS_REGION="${2}"

if [ "$CONN_ARN" = "null" ] || [ -z "$CONN_ARN" ] || [ "$CONN_ARN" = "" ]; then
  echo "ERROR: use_github_native is true but no GitHub connection was found or determined." >&2
  echo "" >&2
  echo "Verify:" >&2
  echo "   1. The GitHub connection exists and is authorized in the AWS console" >&2
  echo "   2. The connection status is 'AVAILABLE' (not 'PENDING')" >&2
  echo "   3. The connection ARN is correct (if provided via github_connection_arn variable)" >&2
  echo "   4. The project org matches the connection name" >&2
  echo "" >&2
  echo "   To authorize the connection, access:" >&2
  echo "   https://console.aws.amazon.com/codesuite/settings/connections" >&2
  exit 1
fi

echo "🔍 Checking GitHub connection status: $CONN_ARN" >&2
CONN_STATUS=$(aws codeconnections get-connection \
  --connection-arn "$CONN_ARN" \
  --region "$AWS_REGION" \
  --query 'Connection.ConnectionStatus' \
  --output text 2>/dev/null || echo "ERROR")

if [ "$CONN_STATUS" = "ERROR" ]; then
  echo "⚠️  Error checking connection status. Trying to continue..." >&2
  CONN_STATUS="UNKNOWN"
fi

echo "   Current status: $CONN_STATUS" >&2

if [ "$CONN_STATUS" != "AVAILABLE" ]; then
  echo "ERROR: GitHub connection is not available (status: $CONN_STATUS)" >&2
  echo "   ARN: $CONN_ARN" >&2
  echo "" >&2
  echo "   The connection must have status 'AVAILABLE' before creating CodeBuild projects." >&2
  echo "   Current status: $CONN_STATUS" >&2
  echo "" >&2
  if [ "$CONN_STATUS" = "PENDING" ]; then
    echo "   The connection is awaiting authorization in the AWS console." >&2
  fi
  echo "" >&2
  echo "   To authorize the connection, access:" >&2
  echo "   https://console.aws.amazon.com/codesuite/settings/connections" >&2
  echo "   Find the connection and click 'Update pending connection' to authorize." >&2
  exit 1
fi

echo "✅ GitHub connection validated: $CONN_ARN (status: $CONN_STATUS)"
