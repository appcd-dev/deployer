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
  echo "[INFO] Deployment completed successfully. Checking deployed resources..."
  
  # Output pod statuses to stdout so they're captured in logs
  # This helps diagnose why wait_for_ready.py might timeout
  if command -v kubectl >/dev/null 2>&1; then
    # Get namespace from service account if available
    namespace=""
    if [ -f /var/run/secrets/kubernetes.io/serviceaccount/namespace ]; then
      namespace=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace 2>/dev/null || echo "")
    fi
    
    echo "[INFO] ========== POST-DEPLOYMENT STATUS CHECK =========="
    
    # Check stackgen namespace pods
    if kubectl get namespace stackgen >/dev/null 2>&1; then
      echo "[INFO] --- Pods in stackgen namespace ---"
      kubectl get pods -n stackgen -o wide 2>&1 | tee /dev/stderr || true
      
      echo "[INFO] --- Pod status details ---"
      for pod in $(kubectl get pods -n stackgen -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo ""); do
        if [ -n "$pod" ]; then
          phase=$(kubectl get pod -n stackgen "$pod" -o jsonpath='{.status.phase}' 2>&1 || echo "Unknown")
          ready=$(kubectl get pod -n stackgen "$pod" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>&1 || echo "Unknown")
          echo "[INFO] Pod: $pod | Phase: $phase | Ready: $ready"
          
          # If pod is not ready, show why
          if [ "$ready" != "True" ] && [ "$phase" != "Running" ]; then
            echo "[WARNING] Pod $pod is not ready. Showing details:"
            kubectl describe pod -n stackgen "$pod" 2>&1 | grep -A 10 "Status:\|Events:" | tee /dev/stderr || true
            echo "[WARNING] Last 30 lines of logs from $pod:"
            kubectl logs -n stackgen "$pod" --tail=30 2>&1 | tee /dev/stderr || true
          fi
        fi
      done
      
      # Show events
      echo "[INFO] --- Recent events in stackgen namespace ---"
      kubectl get events -n stackgen --sort-by='.lastTimestamp' 2>&1 | tail -20 | tee /dev/stderr || true
    else
      echo "[WARNING] stackgen namespace does not exist - this may indicate a deployment issue"
    fi
    
    # Show current namespace resources if available
    if [ -n "$namespace" ]; then
      echo "[INFO] --- Jobs in current namespace ($namespace) ---"
      kubectl get jobs -n "$namespace" -o wide 2>&1 | tee /dev/stderr || true
    fi
    
    echo "[INFO] ========== END POST-DEPLOYMENT STATUS CHECK =========="
  else
    echo "[WARNING] kubectl not available - skipping pod status check"
  fi
  
  echo "[INFO] Deployment script completed successfully at $(date)"
else
  echo "[ERROR] ========== TERRAFORM APPLY FAILED =========="
  echo "[ERROR] Terraform apply failed with exit code $EXIT_CODE at $(date)!"
  echo "[ERROR] Showing Terraform state for debugging:"
  terraform show -no-color 2>&1 | tee /dev/stderr || true
  echo "[ERROR] Showing Terraform plan output:"
  terraform plan -detailed-exitcode -var "suffix=${SUFFIX}" -var "domain=${DOMAIN}" -var "STACKGEN_PAT=${STACKGEN_PAT}" -var "pre_shared_cert_name=${PRE_SHARED_CERT_NAME}" -var "global_static_ip_name=${GLOBAL_STATIC_IP_NAME}" 2>&1 | tee /dev/stderr || true
  echo "[ERROR] ========== END ERROR OUTPUT =========="
  exit $EXIT_CODE
fi
