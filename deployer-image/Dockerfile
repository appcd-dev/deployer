# Stage 1: Build stage for preprocessing schema.yaml (optional)
FROM marketplace.gcr.io/google/debian10 AS build

# Install gettext for envsubst
RUN apt-get update && apt-get install -y --no-install-recommends gettext && rm -rf /var/lib/apt/lists/*

# Copy the schema.yaml into the build stage
ADD marketplace/schema.yaml /workspace/schema.yaml

# Stage 2: Final deployer with Terraform
FROM gcr.io/cloud-marketplace-tools/k8s/deployer_envsubst:latest

# Install Terraform
RUN apt-get update && apt-get install -y wget unzip \
    && wget https://releases.hashicorp.com/terraform/1.5.3/terraform_1.5.3_linux_amd64.zip \
    && unzip terraform_1.5.3_linux_amd64.zip -d /usr/local/bin/ \
    && rm terraform_1.5.3_linux_amd64.zip \
    && apt-get remove -y wget unzip && apt-get autoremove -y && apt-get clean

# Copy schema.yaml from the build stage to the deployer location
COPY --from=build /workspace/schema.yaml /data/schema.yaml

# Copy Kubernetes manifest templates
COPY marketplace/manifests /data/manifest/

# Copy Terraform configurations
COPY terraform/ /data/terraform/

# Copy deployment script
COPY scripts/deploy.sh /data/deploy.sh
RUN chmod +x /data/deploy.sh

