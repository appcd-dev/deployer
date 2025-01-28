# Stage 1: Preprocessing schema.yaml
FROM marketplace.gcr.io/google/debian10 AS build

# Install tools for envsubst
RUN apt-get update && apt-get install -y --no-install-recommends gettext && rm -rf /var/lib/apt/lists/*

# Copy schema.yaml and preprocess it with envsubst
COPY marketplace/schema.yaml /workspace/schema.yaml
RUN envsubst < /workspace/schema.yaml > /workspace/schema.yaml.processed && \
    mv /workspace/schema.yaml.processed /workspace/schema.yaml

# Stage 2: Deployer
FROM gcr.io/cloud-marketplace-tools/k8s/deployer_envsubst:latest

ARG TERRAFORM_VERSION=1.5.3

RUN apt-get update && apt-get install -y wget unzip git \
    && wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin/ \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && apt-get remove -y wget unzip && apt-get autoremove -y && apt-get clean

# LABEL com.googleapis.cloudmarketplace.product.service.name=services/stackgen-enterprise-platform-k8s-v2.endpoints.stackgen-gcp-marketplace.cloud.goog

# Copy processed schema.yaml
COPY --from=build /workspace/schema.yaml /data/schema.yaml

# Copy Kubernetes manifests
COPY marketplace/manifests /data/manifest/

# Copy Terraform configurations
COPY terraform/ /data/terraform/
COPY marketplace/data-test/ /data-test/
# Copy deployment script
COPY scripts/deploy.sh /data/deploy.sh
RUN chmod +x /data/deploy.sh

# Define entrypoint
ENTRYPOINT ["/data/deploy.sh"]
