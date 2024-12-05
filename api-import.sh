#!/usr/bin/env bash

# repo ref: https://github.com/snyk/snyk-api-import
# documentation ref: 

set -xeou pipefail
IFS=$'\t\n'

## Util to run api-import tool against github-enterprise brokered deployment

# Set env vars

# All generated files will be at this path
export SNYK_LOG_PATH=~/snyk-logs

# CONCURRENT_IMPORTS - Defaults to 15 defaults to 15 repos at a time
# Just 1 repo may have many projects inside which can trigger a many files at once to be requested from 
# the user's SCM instance and some may have rate limiting in place. This
# script aims to help reduce the risk of hitting a rate limit.
export CONCURRENT_IMPORTS=15

# Necessary github Info 
export GITHUB_TOKEN=$GITHUB_TOKEN
export GITHUB_ENTERPRISE_URL=$GITHUB_ENTERPRISE_URL

# Necessary Snyk Info
export SNYK_TOKEN=$SNYK_TOKEN
export SNYK_GROUP_ID=$SNYK_GROUP_ID
export SNYK_TEMPLATE_ORG_ID=$SNYK_TEMPLATE_ORG_ID

# Create orgs data from Github Enterprise server API

snyk-api-import orgs:data -source=github-enterprise --groupId="$SNYK_GROUP_ID" --sourceUrl="$GITHUB_ENTERPRISE_URL" 

# Check orgs data

cat "group-$SNYK_GROUP_ID-github-enterprise-orgs.json" ## this file can be generated anyway and passed to import:data until
cmd $("ORG_DATA=group-$SNYK_GROUP_ID-github-enterprise-orgs.json")

# Create orgs in snyk from ORG_DATA via SNYK API

snyk-api-import orgs:create --file="$ORG_DATA" --no-includeExistingOrgsInOutput --noDuplicateNames --sourceOrgId="$SNYK_TEMPLATE_ORG_ID"

# Verify the created orgs (genereated by orgs:create command)

cat snyk-created-orgs.json 
CREATED_ORGS=snyk-created-orgs.json

# Generate import data (via github Server API)

snyk-api-import import:data --orgsData="$CREATED_ORGS" --source=github-enterprise \
  --sourceUrl="$GITHUB_ENTERPRISE_URL" --integrationType=github-enterprise

# Check the import projects file (generated by import:data command)

cat import-projects.json
IMPORT_PROJECTS=import-projects.json
read -r -p "Press enter if you're ready to conitnue"

# Kick off an Import using existing brokered github enterprise integration via snyk api
snyk-api-import import --file="$IMPORT_PROJECTS"

## docs to sync: https://github.com/snyk/snyk-api-import/blob/master/docs/sync.md