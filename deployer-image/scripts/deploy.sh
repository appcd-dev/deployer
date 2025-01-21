#!/bin/bash
set -e

echo ">>> Running Terraform with variables from environment"

cd /app/terraform

# Initialize Terraform
terraform init

# Apply using environment variable values:
terraform apply \
  -var "project_id=${PROJECT_ID}" \
  -var "region=${REGION}" \
  -var "suffix=${SUFFIX}" \
  -var "domain=${DOMAIN}" \
  -var "STACKGEN_PAT=${STACKGEN_PAT}" \
  -auto-approve

echo ">>> Terraform apply complete!"
