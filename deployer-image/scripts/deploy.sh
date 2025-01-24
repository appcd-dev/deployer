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
  -var "pre_shared_cert_name=${PRE_SHARED_CERT_NAME}" \
  -var "global_static_ip_name=${GLOBAL_STATIC_IP_NAME}" \
  -auto-approve

echo ">>> Terraform apply complete!"
