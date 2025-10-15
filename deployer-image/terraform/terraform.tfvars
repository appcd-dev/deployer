# StackGen GCP Deployer - Test Configuration

suffix       = "test-marketplace"
domain       = "test.stackgen.local"
STACKGEN_PAT = "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"

# GCP Resources (for testing, use dummy values)
global_static_ip_name = "test-stackgen-ip"
pre_shared_cert_name  = "test-stackgen-cert"

# NGINX Configuration (optional, using defaults)
nginx_config = {
  client_max_body_size = "10M"
}

