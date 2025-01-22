#!/bin/bash
set -e

# Run Terraform
cd /data/terraform

terraform init
terraform apply \
  -var "project_id=${PROJECT_ID}" \
  -var "region=${REGION}" \
  -var "suffix=${SUFFIX}" \
  -var "domain=${DOMAIN}" \
  -var "STACKGEN_PAT=${STACKGEN_PAT}" \
  -auto-approve

echo ">>> Terraform apply complete!"
