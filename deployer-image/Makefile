# Makefile for managing mpdev and related commands

# Paths and binaries
BIN_DIR := $(HOME)/bin
MPDEV := $(BIN_DIR)/mpdev
SCHEMA_FILE := marketplace/schema.yaml
MANIFEST_DIR := marketplace/manifests
VERSION ?= latest

# Default values for build, install, and verify commands
REGISTRY ?= gcr.io/platform-439702
APP_NAME ?= terraform-deployer
DEPLOYER_IMAGE ?= $(REGISTRY)/$(APP_NAME)/deployer:$(VERSION)
WAIT_TIMEOUT ?= 600

# Parameters for mpdev install
PROJECT_ID ?= "platform-439702"
REGION ?= "us-central1"
SUFFIX ?= "refined"
DOMAIN ?= "test.app"
STACKGEN_PAT ?= "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"
NAME ?= "my-app-instance"
NAMESPACE ?= "default"
OPERATOR_SERVICE_ACCOUNT ?= "stackgen-deployer-sa"

# Construct PARAMETERS JSON for mpdev install
PARAMETERS := $(shell printf '{"name": "%s", "namespace": "%s", "projectId": "%s", "region": "%s", "domain": "%s", "stackgenPat": "%s"}' \
  $(NAME) $(NAMESPACE) $(PROJECT_ID) $(REGION) $(DOMAIN) $(STACKGEN_PAT))


.PHONY: all setup doctor install-deployment verify validate render-manifests apply-manifests help

all: help

build:
	@echo "Building deployer image: $(DEPLOYER_IMAGE)"
	@docker buildx build \
	  --platform linux/amd64 \
	  -t $(DEPLOYER_IMAGE) \
	  --load .

push:
	@echo "Pushing deployer image: $(DEPLOYER_IMAGE)"
	@docker buildx build \
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

# Verify an application deployment
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

# Display usage information
help:
	@echo "Available targets:"
	@echo "  setup             - Setup the mpdev tool"
	@echo "  doctor            - Diagnose your environment using mpdev doctor"
	@echo "  install-deployment- Install an application using mpdev install with parameters"
	@echo "                      (override NAME, NAMESPACE, PROJECT_ID, REGION, etc. as needed)"
	@echo "  verify            - Verify an application using mpdev verify"
	@echo "                      (use DEPLOYER_IMAGE and WAIT_TIMEOUT variables to override defaults)"
	@echo "  validate          - Validate the schema.yaml file using mpdev validate"
	@echo "  render-manifests  - Render Kubernetes manifest templates by substituting variables"
	@echo "  apply-manifests   - Render and apply Kubernetes manifests to the cluster"
	@echo "  help              - Display this help message"
