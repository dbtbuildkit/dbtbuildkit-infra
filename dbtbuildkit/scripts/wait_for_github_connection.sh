#!/bin/bash
# Script to wait for GitHub connection approval in AWS console
# Loops checking status until it changes from PENDING to AVAILABLE

set -e

CONNECTION_ARN="$1"
AWS_REGION="${2:-us-east-1}"
MAX_WAIT_MINUTES="${3:-30}"
CHECK_INTERVAL_SECONDS="${4:-10}"

if [ -z "$CONNECTION_ARN" ]; then
  echo "ERROR: Connection ARN not provided"
  exit 1
fi

echo "🔗 Waiting for GitHub connection approval..."
echo "   ARN: ${CONNECTION_ARN}"
echo "   Region: ${AWS_REGION}"
echo "   Maximum wait time: ${MAX_WAIT_MINUTES} minutes"
echo "   Check interval: ${CHECK_INTERVAL_SECONDS} seconds"
echo ""
echo "📋 Please access the AWS console and approve the connection:"
echo "   https://console.aws.amazon.com/codesuite/settings/connections"
echo ""

MAX_ITERATIONS=$((MAX_WAIT_MINUTES * 60 / CHECK_INTERVAL_SECONDS))
ITERATION=0

while [ $ITERATION -lt $MAX_ITERATIONS ]; do

  STATUS=$(aws codeconnections get-connection \
    --connection-arn "$CONNECTION_ARN" \
    --region "$AWS_REGION" \
    --query 'Connection.ConnectionStatus' \
    --output text 2>/dev/null || echo "ERROR")

  if [ "$STATUS" = "ERROR" ]; then
    echo "⚠️  Error getting connection status. Retrying..."
    sleep $CHECK_INTERVAL_SECONDS
    ITERATION=$((ITERATION + 1))
    continue
  fi

  echo "[$(date +'%H:%M:%S')] Current status: ${STATUS}"

  case "$STATUS" in
    "AVAILABLE")
      echo ""
      echo "✅ Connection approved and available!"
      exit 0
      ;;
    "PENDING")
      echo "   ⏳ Waiting for approval in AWS console..."
      ;;
    "ERROR")
      echo "   ❌ Connection error. Please check in AWS console."
      exit 1
      ;;
    *)
      echo "   ℹ️  Unknown status: ${STATUS}"
      ;;
  esac

  sleep $CHECK_INTERVAL_SECONDS
  ITERATION=$((ITERATION + 1))
done

echo ""
echo "⏰ Maximum wait time exceeded (${MAX_WAIT_MINUTES} minutes)"
echo "   Connection still has status: ${STATUS}"
echo "   Please check manually in AWS console"
exit 1
