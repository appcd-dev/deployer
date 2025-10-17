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

ARG TERRAFORM_VERSION=1.10.3
ARG YQ_VERSION=4.44.6

# Update base system and install security patches
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        unzip \
        git \
        jq && \
    # Install Terraform
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin/ && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    # Install yq with specific version
    wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq && \
    # Upgrade pip to latest version to fix CVE-2024-35195 and CVE-2025-47273
    python3 -m pip install --upgrade pip setuptools wheel --no-cache-dir && \
    # Clean up
    apt-get remove -y wget unzip && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

LABEL com.googleapis.cloudmarketplace.product.service.name=services/stackgen-enterprise-platform-k8s-v2.endpoints.stackgen-gcp-marketplace.cloud.goog

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
