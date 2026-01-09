FROM alpine AS test_schema_creator

WORKDIR /app

ARG GH_TOKEN

COPY marketplace/data-test/schema.yaml .

RUN apk add --no-cache yq && \
    echo "$GH_TOKEN" | tr -d '\n' > /tmp/gh_token && \
    yq -i ".properties.stackgenPat.default = \"$GH_TOKEN\"" schema.yaml
    
# Stage 1: Preprocessing schema.yaml
FROM marketplace.gcr.io/google/debian11 AS build

# Install tools for envsubst
RUN apt-get update && apt-get install -y --no-install-recommends gettext && rm -rf /var/lib/apt/lists/*

# Copy schema.yaml and preprocess it with envsubst
COPY marketplace/schema.yaml /workspace/schema.yaml
RUN envsubst < /workspace/schema.yaml > /workspace/schema.yaml.processed && \
    mv /workspace/schema.yaml.processed /workspace/schema.yaml

# Stage 2: Deployer
FROM gcr.io/cloud-marketplace-tools/k8s/deployer_envsubst:latest

ARG TERRAFORM_VERSION=1.13.4
ARG YQ_VERSION=4.44.6

# Update base system and install security patches
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        unzip \
        git \
        jq \
        curl && \
    # Install Terraform
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin/ && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    # Install yq with specific version
    wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq && \
    # Install latest kubectl versions to fix CVE-2025-8959, CVE-2025-61729, and CVE-2025-22868
    # These vulnerabilities affect kubectl binaries built with vulnerable Go dependencies
    # Installing latest kubectl versions that were built with fixed Go 1.22.6+ and updated dependencies
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
    mkdir -p /opt/kubectl/1.30 /opt/kubectl/1.31 && \
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256" && \
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check && \
    chmod +x kubectl && \
    cp kubectl /opt/kubectl/1.30/kubectl && \
    cp kubectl /opt/kubectl/1.31/kubectl && \
    cp kubectl /usr/local/bin/kubectl && \
    rm kubectl kubectl.sha256 && \
    # Upgrade pip to latest version to fix CVE-2024-35195 and CVE-2025-47273
    python3 -m pip install --upgrade pip setuptools wheel --no-cache-dir && \
    # Clean up
    apt-get remove -y wget unzip curl && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

LABEL com.googleapis.cloudmarketplace.product.service.name=services/stackgen-enterprise-platform-k8s-v2.endpoints.stackgen-gcp-marketplace.cloud.goog

# Set timeout for Application readiness check (default is 300 seconds)
# Increased to 600 seconds (10 minutes) to allow for longer deployment times
ENV WAIT_FOR_READY_TIMEOUT=600

# Set timeout for the entire tester process (deploying, running tester pods, waiting for completion)
# Increased to 900 seconds (15 minutes) to allow for longer deployment and testing times
ENV TESTER_TIMEOUT=900

# Enable debug logging by default to help diagnose issues
# Set to "false" to disable verbose output and Terraform debug logs
ENV DEBUG=true

# Copy processed schema.yaml
COPY --from=build /workspace/schema.yaml /data/schema.yaml

# Copy Kubernetes manifests
COPY marketplace/manifests /data/manifest/

COPY marketplace/data-test/manifest/ /data-test/manifest/
COPY --from=test_schema_creator /app/schema.yaml /data-test/schema.yaml
COPY scripts/deploy.sh /data/deploy.sh
RUN chmod +x /data/deploy.sh

# Copy Terraform configurations
COPY terraform/ /data/terraform/

# Define entrypoint
ENTRYPOINT ["/data/deploy.sh"]