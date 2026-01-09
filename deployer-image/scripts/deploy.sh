#!/bin/bash
set -e

# Enable debug mode if DEBUG environment variable is set
if [ "${DEBUG:-false}" = "true" ]; then
  set -x
  export TF_LOG=INFO
fi

# Debug: Print script start time
echo "[INFO] Starting deployment at $(date)"
echo "[DEBUG] Working directory: $(pwd)"
echo "[DEBUG] Environment variables:"
echo "  DEBUG=${DEBUG:-false}"
echo "  WAIT_FOR_READY_TIMEOUT=${WAIT_FOR_READY_TIMEOUT:-300}"
echo "  TESTER_TIMEOUT=${TESTER_TIMEOUT:-300}"
echo "[DEBUG] All environment variables containing TIMEOUT:"
env | grep -i timeout || echo "  (none found)"
echo "[DEBUG] Process info:"
echo "  PID: $$"
echo "  Command: $0 $*"

VALUES_FILE="/data/values.yaml"
if [ ! -f "$VALUES_FILE" ]; then
  echo "[ERROR] Values file not found: $VALUES_FILE"
  ls -la /data/ || true
  exit 1
fi

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
echo "[DEBUG] Changed to Terraform directory: $(pwd)"
echo "[DEBUG] Terraform files present:"
ls -la || true

echo "[INFO] Initializing Terraform"
terraform init -input=false

if [ $? -ne 0 ]; then
  echo "[ERROR] Terraform initialization failed!"
  exit 1
fi

echo "[INFO] Applying Terraform configuration"
echo "[DEBUG] Terraform version: $(terraform version | head -1)"
terraform apply \
  -var "suffix=${SUFFIX}" \
  -var "domain=${DOMAIN}" \
  -var "STACKGEN_PAT=${STACKGEN_PAT}" \
  -var "pre_shared_cert_name=${PRE_SHARED_CERT_NAME}" \
  -var "global_static_ip_name=${GLOBAL_STATIC_IP_NAME}" \
  -auto-approve

EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
  echo "[INFO] Terraform apply complete at $(date)!"
else
  echo "[ERROR] Terraform apply failed with exit code $EXIT_CODE at $(date)!"
  echo "[DEBUG] Showing Terraform state for debugging:"
  terraform show -no-color || true
  exit $EXIT_CODE
fi
