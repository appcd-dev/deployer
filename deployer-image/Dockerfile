FROM alpine AS test_schema_creator

WORKDIR /app

ARG GH_TOKEN

COPY marketplace/data-test/schema.yaml .

RUN apk add --no-cache yq && \
    echo "$GH_TOKEN" | tr -d '\n' > /tmp/gh_token && \
    yq -i ".properties.stackgenPat.default = \"$GH_TOKEN\"" schema.yaml
    
# Stage 1: Preprocessing schema.yaml
# Build-only. Its sole output is /workspace/schema.yaml, so this base does not
# ship in the image. Debian 11 is EOL and bullseye-security now 404s on
# libicu67 and libxml2, which made `apt-get install gettext` fail the 4.2.9 tag.
FROM debian:bookworm-slim AS build

RUN apt-get update && \
    apt-get install -y --no-install-recommends gettext-base && \
    rm -rf /var/lib/apt/lists/*

# Copy schema.yaml and preprocess it with envsubst
COPY marketplace/schema.yaml /workspace/schema.yaml
RUN envsubst < /workspace/schema.yaml > /workspace/schema.yaml.processed && \
    mv /workspace/schema.yaml.processed /workspace/schema.yaml

# Stage 1c: Build Terraform and yq from source with a patched Go toolchain.
# GCP Marketplace scanning flags the Go stdlib version embedded in each binary.
# CVE-2026-56857 and CVE-2026-78663 need go1.27.2+, CVE-2026-97040 needs
# go1.27.4+. The released Terraform and yq binaries predate go1.27.4, so
# compile the same source tags here instead.
FROM golang:1.27.4-bookworm AS go-tools-build
ARG TERRAFORM_VERSION=1.16.1
ARG YQ_VERSION=4.54.3
RUN git clone --depth 1 --branch v${TERRAFORM_VERSION} \
      https://github.com/hashicorp/terraform.git /src/terraform && \
    git clone --depth 1 --branch v${YQ_VERSION} \
      https://github.com/mikefarah/yq.git /src/yq
WORKDIR /src/terraform
RUN CGO_ENABLED=0 GOTOOLCHAIN=local \
    go build -trimpath \
      -ldflags="-s -w -X github.com/hashicorp/terraform/version.dev=no" \
      -o /out/terraform .
WORKDIR /src/yq
RUN CGO_ENABLED=0 GOTOOLCHAIN=local \
    go build -trimpath -ldflags="-s -w" -o /out/yq .

# Stage 1d: Build kubectl from source.
# Kubernetes 1.37.2 ships kubectl built with go1.26.10, which still carries
# CVE-2026-97040 (fixed in go1.26.11). Kubernetes 1.37 targets the go1.26 line.
FROM golang:1.26.11-bookworm AS kubectl-build
ARG KUBECTL_VERSION=1.37.2
RUN git clone --depth 1 --branch v${KUBECTL_VERSION} \
      https://github.com/kubernetes/kubernetes.git /src
WORKDIR /src
RUN CGO_ENABLED=0 GOTOOLCHAIN=local \
    go build -trimpath \
      -ldflags="-s -w \
        -X k8s.io/client-go/pkg/version.gitVersion=v${KUBECTL_VERSION} \
        -X k8s.io/component-base/version.gitVersion=v${KUBECTL_VERSION} \
        -X k8s.io/client-go/pkg/version.gitTreeState=clean \
        -X k8s.io/component-base/version.gitTreeState=clean" \
      -o /out/kubectl ./cmd/kubectl

# Stage 2: Deployer
FROM gcr.io/cloud-marketplace-tools/k8s/deployer_envsubst:latest

COPY --from=go-tools-build /out/yq /usr/local/bin/yq
COPY --from=kubectl-build /out/kubectl /tmp/kubectl

# Update base system and install security patches.
# apt-get upgrade picks up libbrotli1 1.0.9-2+deb12u1 (CVE-2026-111497).
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        unzip \
        git \
        jq \
        curl && \
    # The base image ships its own kubectl copies under /opt/kubectl/v<minor>/,
    # which the Marketplace deployer framework selects from at runtime. Overwrite
    # every directory the base ships rather than hardcoding versions.
    echo "Patching base-image kubectl copies:" && ls -d /opt/kubectl/*/ && \
    ls -d /opt/kubectl/*/ | while read -r d; do cp /tmp/kubectl "${d}kubectl"; done && \
    mv /tmp/kubectl /usr/local/bin/kubectl && \
    # Upgrade pip and fix CVE-2026-27459 (pyOpenSSL buffer overflow in DTLS cookie callback)
    python3 -m pip install --upgrade pip setuptools wheel "pyOpenSSL>=26.0.0" "cryptography>=46.0.7" --no-cache-dir && \
    # Clean up
    apt-get remove -y wget unzip curl && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=go-tools-build /out/terraform /usr/local/bin/terraform

LABEL com.googleapis.cloudmarketplace.product.service.name=services/stackgen-enterprise-platform-k8s-v2.endpoints.stackgen-gcp-marketplace.cloud.goog

# Set timeout for Application readiness check (default is 300 seconds)
# Increased to 900 seconds (15 minutes) to allow for heavy Terraform deployment
# (PostgreSQL + Temporal + Stackgen Helm charts all with wait=true)
ENV WAIT_FOR_READY_TIMEOUT=900

# Set timeout for the entire tester process (deploying, running tester pods, waiting for completion)
# Increased to 1200 seconds (20 minutes) to allow for longer deployment and testing times
ENV TESTER_TIMEOUT=1200

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
