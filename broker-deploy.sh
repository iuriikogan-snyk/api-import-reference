#!/usr/bin/env bash
set -eou pipefail

# Function to handle errors
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# 
# Snyk broker deployment for github enterprise
# Documentation Link: https://docs.snyk.io/enterprise-setup/snyk-broker/install-and-configure-snyk-broker/github-enterprise-prerequisites-and-steps-to-install-and-configure-broker/github-enterprise-install-and-configure-using-helm

# required envs
export INTEGRATION_ID=$INTEGRATION_ID
export ORG_ID=$ORG_ID
export SNYK_TOKEN=$SNYK_TOKEN
export GITHUB_TOKEN=$GITHUB_TOKEN
export BROKER_CLIENT_URL=$BROKER_CLIENT_URL
export BROKER_CLIENT_PORT=$BROKER_CLIENT_PORT

# For github, githubApi and githubGraphQl values do not include https://
export GITHUB_URL=$GITHUB_URL
export GITHUB_API_URL=$GITHUB_API_URL
export GITHUB_GRAPHQL_URL=$GITHUB_GRAPHQL_URL

## create a broker token !!!!!! you can only get in once via this command if you need it again for any reason it'll be available in the org/integration settings

curl "https://api.snyk.io/v1/org/$ORG_ID/integrations/$INTEGRATION_ID" \
  -H "Authorization: token $SNYK_TOKEN" \
  -H "Content-Type: application/json" \
  -X PUT -d \
  '{
    "type": "github-enterprise",
    "broker": { "enabled" : true }
}' | jq -r .brokerToken

export BROKER_TOKEN=$BROKER_TOKEN

helm repo add snyk-broker https://snyk.github.io/snyk-broker-helm/
helm repo update

helm upgrade --install snyk-broker-chart snyk-broker/snyk-broker \
  --set scmType=github-enterprise \
  --set brokerToken="$BROKER_TOKEN" \
  --set scmToken="$GITHUB_TOKEN" \
  --set github="$GITHUB_URL" \
  --set githubApi="$GITHUB_API_URL" \
  --set githubGraphQl="$GITHUB_GRAPHQL_URL" \
  --set enableAppRisk=true \
  --set brokerClientUrl="$BROKER_CLIENT_URL:$BROKER_CLIENT_PORT" \
  --set service.brokerType=LoadBalancer \
  -n snyk-broker --create-namespace