#!/bin/bash
# Script to list CodeConnections and extract information
# Returns JSON in the format expected by Terraform external data source

set -euo pipefail

REGION="${1:-us-east-1}"

set +e
CONNECTIONS=$(aws codeconnections list-connections \
  --provider-type-filter GitHub \
  --region "$REGION" \
  --query 'Connections[*].[ConnectionArn,ConnectionName]' \
  --output json 2>&1)
AWS_EXIT_CODE=$?
set -e

if [ $AWS_EXIT_CODE -ne 0 ]; then
  echo "WARNING: Error listing CodeConnections: $CONNECTIONS" >&2
  CONNECTIONS='[]'
fi

if [ -z "$CONNECTIONS" ] || [ "$CONNECTIONS" = "null" ]; then
  CONNECTIONS='[]'
fi

if ! echo "$CONNECTIONS" | jq empty 2>/dev/null; then
  echo "WARNING: Invalid response from AWS CLI, using empty array" >&2
  CONNECTIONS='[]'
fi

FINAL_CONNECTIONS="[]"
if [ "$CONNECTIONS" != "[]" ] && [ "$CONNECTIONS" != "null" ]; then

  COMMON_WORDS="github|connection|prd|dev|stg|prod|production|development|staging|test|qa|uat|gh|conn"
  

  CONN_COUNT=$(echo "$CONNECTIONS" | jq 'length')
  echo "DEBUG: Processing $CONN_COUNT connection(s)" >&2
  
  if [ "$CONN_COUNT" -gt 0 ]; then
    for i in $(seq 0 $((CONN_COUNT - 1))); do
    CONN=$(echo "$CONNECTIONS" | jq -c ".[$i]")
    
    if [ -z "$CONN" ] || [ "$CONN" = "null" ]; then
      continue
    fi
    
    ARN=$(echo "$CONN" | jq -r '.[0] // empty')
    NAME=$(echo "$CONN" | jq -r '.[1] // empty')
    
    if [ -z "$ARN" ] || [ -z "$NAME" ]; then
      echo "WARNING: Connection with incomplete data ignored" >&2
      continue
    fi
    
    echo "DEBUG: Processing connection: $NAME (ARN: $ARN)" >&2
    

    STATUS=$(aws codeconnections get-connection \
      --connection-arn "$ARN" \
      --region "$REGION" \
      --query 'Connection.ConnectionStatus' \
      --output text 2>/dev/null || echo "UNKNOWN")
    
    echo "DEBUG: Connection $NAME status: $STATUS" >&2
    

    POSSIBLE_ORGS=$(echo "$NAME" | jq -Rr 'split("-") | map(select(. != "" and (. | test("^('"$COMMON_WORDS"')$"; "i") | not))) | .[]' | jq -R -s 'split("\n") | map(select(. != ""))')
    

    TAGS=$(aws codeconnections list-tags-for-resource \
      --resource-arn "$ARN" \
      --region "$REGION" \
      --output json 2>/dev/null | jq -c '.Tags // []' || echo '[]')
    

    CONN_OBJ=$(echo "{\"arn\":\"$ARN\",\"name\":\"$NAME\",\"status\":\"$STATUS\"}" | \
      jq --argjson possible_orgs "$POSSIBLE_ORGS" \
         --argjson tags "$TAGS" \
         '. + {possible_orgs: $possible_orgs, tags: $tags}')
    
    FINAL_CONNECTIONS=$(echo "$FINAL_CONNECTIONS" | jq --argjson conn "$CONN_OBJ" '. + [$conn]')
    done
  fi
fi

OUTPUT=$(echo "$FINAL_CONNECTIONS" | jq -c '{
  connections: (. | tostring)
}')

echo "DEBUG: Total connections found: $(echo "$FINAL_CONNECTIONS" | jq 'length')" >&2
echo "DEBUG: Connections: $(echo "$FINAL_CONNECTIONS" | jq -c '.')" >&2

echo "$OUTPUT"
