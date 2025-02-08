#!/bin/bash
set -e

# Debug: Print script start time
echo "[INFO] Starting deployment at $(date)"
VALUES_FILE="/data/values.yaml"
# Extract values from values.yaml using yq if environment variables are not already set
SUFFIX=${SUFFIX:-$(yq '.suffix' $VALUES_FILE)}
DOMAIN=${DOMAIN:-$(yq '.domain' $VALUES_FILE)}
STACKGEN_PAT=${STACKGEN_PAT:-$(yq '.stackgenPat' $VALUES_FILE)}
PRE_SHARED_CERT_NAME=${PRE_SHARED_CERT_NAME:-$(yq '.pre_shared_cert_name' $VALUES_FILE)}
GLOBAL_STATIC_IP_NAME=${GLOBAL_STATIC_IP_NAME:-$(yq '.global_static_ip_name' $VALUES_FILE)}

# Debug: Print extracted values
echo "[INFO] Extracted values:"
echo "  SUFFIX: $SUFFIX"
echo "  DOMAIN: $DOMAIN"
echo "  STACKGEN_PAT: [REDACTED]"
echo "  PRE_SHARED_CERT_NAME: $PRE_SHARED_CERT_NAME"
echo "  GLOBAL_STATIC_IP_NAME: $GLOBAL_STATIC_IP_NAME"

# Run Terraform
cd /data/terraform

echo "[INFO] Initializing Terraform"
terraform init

echo "[INFO] Applying Terraform configuration"
terraform apply \
  -var "suffix=${SUFFIX}" \
  -var "domain=${DOMAIN}" \
  -var "STACKGEN_PAT=${STACKGEN_PAT}" \
  -var "pre_shared_cert_name=${PRE_SHARED_CERT_NAME}" \
  -var "global_static_ip_name=${GLOBAL_STATIC_IP_NAME}" \
  -auto-approve

if [ $? -eq 0 ]; then
  echo "[INFO] Terraform apply complete!"
else
  echo "[ERROR] Terraform apply failed!"
  exit 1
fi
