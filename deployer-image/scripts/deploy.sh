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

# Marketplace component pins feed both Helm and the proxy /version.json response.
APPCD_VERSION=${APPCD_VERSION:-$(yq '.appcdVersion // "v2025.1.3"' "$VALUES_FILE")}
IACGEN_VERSION=${IACGEN_VERSION:-$(yq '.iacgenVersion // "v0.22.0"' "$VALUES_FILE")}
UI_VERSION=${UI_VERSION:-$(yq '.uiVersion // "v0.10.11"' "$VALUES_FILE")}
EXPORTER_VERSION=${EXPORTER_VERSION:-$(yq '.exporterVersion // "v0.4.0"' "$VALUES_FILE")}
LLM_GATEWAY_VERSION=${LLM_GATEWAY_VERSION:-$(yq '.llmGatewayVersion // "v0.2.3"' "$VALUES_FILE")}
VAULT_VERSION=${VAULT_VERSION:-$(yq '.vaultVersion // "v0.1.0"' "$VALUES_FILE")}
GUILD_VERSION=${GUILD_VERSION:-$(yq '.guildVersion // "disabled"' "$VALUES_FILE")}
GATEWAY_VERSION=${GATEWAY_VERSION:-$(yq '.guildGatewayVersion // "disabled"' "$VALUES_FILE")}
GUILD_UI_VERSION=${GUILD_UI_VERSION:-$(yq '.guildUiVersion // "disabled"' "$VALUES_FILE")}
GUILD_ENABLED=${GUILD_ENABLED:-$(yq '.guildEnabled // false' "$VALUES_FILE")}
COMPONENT_VERSIONS=$(jq -cn \
  --arg appcd "$APPCD_VERSION" --arg iacgen "$IACGEN_VERSION" \
  --arg ui "$UI_VERSION" --arg exporter "$EXPORTER_VERSION" \
  --arg llm_gateway "$LLM_GATEWAY_VERSION" --arg vault "$VAULT_VERSION" \
  --arg guild "$GUILD_VERSION" --arg gateway "$GATEWAY_VERSION" --arg guild_ui "$GUILD_UI_VERSION" \
  '{appcd:$appcd,iacgen:$iacgen,ui:$ui,exporter:$exporter,llm_gateway:$llm_gateway,vault:$vault,guild:$guild,gateway:$gateway,guild_ui:$guild_ui}')

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
  -var "guild_enabled=${GUILD_ENABLED}" \
  -var "component_versions=${COMPONENT_VERSIONS}" \
  -auto-approve

if [ $? -eq 0 ]; then
  echo "[INFO] Terraform apply complete!"
else
  echo "[ERROR] Terraform apply failed!"
  exit 1
fi
