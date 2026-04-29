#!/bin/bash

set -e

# Variables
JIRA_BASE_URL="https://alshayagroup.atlassian.net"
IMPACT_FIELD_ID="customfield_11322"

# Validate required inputs
if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "ERROR: GITHUB_TOKEN is missing"
  exit 1
fi

if [[ -z "$JIRA_USERNAME" || -z "$JIRA_API_TOKEN" ]]; then
  echo "ERROR: JIRA_USERNAME or JIRA_API_TOKEN is missing"
  exit 1
fi

if [[ -z "$PR_TITLE" ]]; then
  echo "ERROR: PR_TITLE is missing"
  exit 1
fi

echo "PR Title: $PR_TITLE"

# Extract Jira Ticket ID from PR title
JIRA_TICKET=$(echo "$PR_TITLE" | sed -E 's/^.*((CORE|LDHUB|CTW)-[0-9]+).*$/\1/' | sed '/ /d')

if [[ -z "$JIRA_TICKET" || "$JIRA_TICKET" == "$PR_TITLE" ]]; then
  echo "ERROR: No Jira ticket ID found in PR title."
  echo "Expected format: CORE-1234 / LDHUB-1234 / CTW-1234"
  exit 1
fi

echo "Jira Ticket Found: $JIRA_TICKET"

# Jira API Call
JIRA_URL="${JIRA_BASE_URL}/rest/api/2/issue/${JIRA_TICKET}?fields=${IMPACT_FIELD_ID}"

response=$(curl -s -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
  -X GET -H "Content-Type: application/json" "${JIRA_URL}")

# Check if Jira ticket exists
jira_key=$(echo "$response" | jq -r '.key // empty')

if [[ -z "$jira_key" ]]; then
  echo "ERROR: Jira ticket not found or API issue."
  echo "$response"
  exit 1
fi

impact_value=$(echo "$response" | jq ".fields.${IMPACT_FIELD_ID}")

if echo "$impact_value" | jq -e '(. == null) or (. == []) or (. == {}) or (tostring | length == 0)' > /dev/null; then
  echo "ERROR: You have not added 'Impact Areas' in Jira ticket ($JIRA_TICKET). Please add it and retry."
  exit 1
else
  echo "SUCCESS: Impact Areas is added in Jira ticket ($JIRA_TICKET)."
fi