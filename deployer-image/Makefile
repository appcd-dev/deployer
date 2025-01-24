# Paths and binaries
BIN_DIR := $(HOME)/bin
MPDEV := $(BIN_DIR)/mpdev
SCHEMA_FILE := marketplace/schema.yaml
MANIFEST_DIR := marketplace/manifests
TEST_SCHEMA_FILE := marketplace/data-test/schema.yaml
VERSION ?= latest

# Default values for build, install, and verify commands
REGISTRY = gcr.io/stackgen-gcp-marketplace
APP_NAME = stackgen-deployer
DEPLOYER_IMAGE ?= $(REGISTRY)/$(APP_NAME)/deployer:$(VERSION)
TESTER_IMAGE ?= $(REGISTRY)/tester:latest
WAIT_TIMEOUT ?= 600

# Parameters for mpdev install
PROJECT_ID ?= "stackgen-gcp-marketplace"
REGION ?= "us-central1"
SUFFIX ?= "refined"
DOMAIN ?= "test.app"
STACKGEN_PAT ?= "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"
NAME ?= "my-app-instance"
NAMESPACE ?= "default"
PRE_SHARED_CERT_NAME ?= "marketplace-go-cloud-stackgen-com"
GLOBAL_STATIC_IP_NAME ?= "proxy-static-ip"


PARAMETERS := $(shell printf '{"name": "%s", "namespace": "%s", "projectId": "%s", "region": "%s", "domain": "%s", "stackgenPat": "%s", "suffix": "%s", "pre_shared_cert_name": "%s", "global_static_ip_name": "%s"}' \
  $(NAME) $(NAMESPACE) $(PROJECT_ID) $(REGION) $(DOMAIN) $(STACKGEN_PAT) $(SUFFIX) $(PRE_SHARED_CERT_NAME) $(GLOBAL_STATIC_IP_NAME))

.PHONY: all setup doctor install-deployment build push verify validate build-tester push-tester verify-tester render-manifests apply-manifests help clean

all: help

# Build and push deployer image
build:
	@echo "Building deployer image: $(DEPLOYER_IMAGE)"
	docker buildx build \
	  --platform linux/amd64 \
	  -t $(DEPLOYER_IMAGE) \
	  --load .

push:
	@echo "Pushing deployer image: $(DEPLOYER_IMAGE)"
	docker buildx build \
	  --platform linux/amd64 \
	  -t $(DEPLOYER_IMAGE) \
	  --push .


# Target to set up mpdev binary in ~/bin
setup:
	@echo "Setting up mpdev..."
	@mkdir -p $(BIN_DIR)
	@docker run gcr.io/cloud-marketplace-tools/k8s/dev cat /scripts/dev > $(MPDEV)
	@chmod +x $(MPDEV)
	@echo "mpdev installed at $(MPDEV)"

# Run environment diagnosis
doctor:
	@echo "Running mpdev doctor..."
	@$(MPDEV) doctor

# Install an application using provided deployer image and parameters
install:
	@echo "Installing application with deployer: $(DEPLOYER_IMAGE)"
	@echo "Using parameters:"
	@echo $(PARAMETERS)
	@$(MPDEV) install \
	  --deployer=$(DEPLOYER_IMAGE) \
	  --parameters='$(PARAMETERS)'

# Verify the deployer
verify:
	@echo "Verifying application with deployer: $(DEPLOYER_IMAGE)"
	@$(MPDEV) verify --deployer=$(DEPLOYER_IMAGE) --wait_timeout=$(WAIT_TIMEOUT)


# Validate the schema.yaml file
validate:
	@echo "Validating schema file: $(SCHEMA_FILE)"
	@$(MPDEV) validate --schema=$(SCHEMA_FILE)

# Render Kubernetes manifest templates
render-manifests:
	@echo "Rendering manifest templates from: $(MANIFEST_DIR)"
	@for template in $(MANIFEST_DIR)/*.yaml.template; do \
		echo "Rendering $$template..."; \
		envsubst < $$template > $$(echo $$template | sed 's/.template$$//'); \
	done
	@echo "Rendered manifests are ready."

# Apply rendered Kubernetes manifests to the cluster
apply-manifests: render-manifests
	@echo "Applying rendered manifests..."
	@kubectl apply -f $(MANIFEST_DIR)
	@echo "Manifests applied successfully."

# Clean up resources
clean:
	@echo "Cleaning up namespace: $(NAMESPACE)"
	kubectl delete namespace $(NAMESPACE) --ignore-not-found=true
	@echo "Cleaning up stackgen namespace..."
	kubectl delete namespace stackgen --ignore-not-found=true

# Display usage information
help:
	@echo "Available targets:"
	@echo "  build             - Build the deployer Docker image"
	@echo "  push              - Push the deployer Docker image to the registry"
	@echo "  build-tester      - Build the tester Docker image"
	@echo "  push-tester       - Push the tester Docker image to the registry"
	@echo "  setup             - Setup the mpdev tool"
	@echo "  doctor            - Diagnose your environment using mpdev doctor"
	@echo "  install           - Install an application using mpdev install with parameters"
	@echo "  verify            - Verify an application using mpdev verify"
	@echo "  verify-tester     - Verify the functionality of the tester image"
	@echo "  validate          - Validate the deployer schema.yaml file"
	@echo "  render-manifests  - Render Kubernetes manifest templates"
	@echo "  apply-manifests   - Apply rendered Kubernetes manifests"
	@echo "  clean             - Clean up resources from the cluster"
	@echo "  help              - Display this help message"
