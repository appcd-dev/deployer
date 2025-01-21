# Makefile for managing mpdev and related commands

# Paths and binaries
BIN_DIR := $(HOME)/bin
MPDEV := $(BIN_DIR)/mpdev
SCHEMA_FILE := marketplace/schema.yaml

# Default values for install and verify commands
DEPLOYER_IMAGE ?= gcr.io/platform-439702/terraform-deployer/deployer:2.9
WAIT_TIMEOUT ?= 600

# Environment variables for parameters
PROJECT_ID ?= "platform-439702"
REGION ?= "us-central1"
SUFFIX ?= "refined"
DOMAIN ?= "test.app"
STACKGEN_PAT ?= "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"
NAME ?= "my-app-instance"
NAMESPACE ?= "default"

# Construct PARAMETERS JSON including the env list
PARAMETERS := $(shell printf '{"name": "%s", "namespace": "%s", "env": [{"name": "PROJECT_ID", "value": "%s"}, {"name": "REGION", "value": "%s"}, {"name": "SUFFIX", "value": "%s"}, {"name": "DOMAIN", "value": "%s"}, {"name": "STACKGEN_PAT", "value": "%s"}]}' $(NAME) $(NAMESPACE) $(PROJECT_ID) $(REGION) $(SUFFIX) $(DOMAIN) $(STACKGEN_PAT))

.PHONY: all setup doctor install-deployment verify validate help

all: help

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

# Install an application using provided deployer image and parameters including env variables
install-deployment:
	@echo "Installing application with deployer: $(DEPLOYER_IMAGE)"
	@echo "Using parameters: $(PARAMETERS)"
	@$(MPDEV) install --deployer=$(DEPLOYER_IMAGE) --parameters='$(PARAMETERS)'

# Verify an application deployment
verify:
	@echo "Verifying application with deployer: $(DEPLOYER_IMAGE)"
	@$(MPDEV) verify --deployer=$(DEPLOYER_IMAGE) --wait_timeout=$(WAIT_TIMEOUT)

# Validate the schema.yaml file
validate:
	@echo "Validating schema file: $(SCHEMA_FILE)"
	@$(MPDEV) validate --schema=$(SCHEMA_FILE)

# Display usage information
help:
	@echo "Available targets:"
	@echo "  setup             - Setup the mpdev tool"
	@echo "  doctor            - Diagnose your environment using mpdev doctor"
	@echo "  install-deployment- Install an application using mpdev install with environment variables"
	@echo "                      (override environment variables like PROJECT_ID, REGION, etc. as needed)"
	@echo "  verify            - Verify an application using mpdev verify"
	@echo "                      (use DEPLOYER_IMAGE and WAIT_TIMEOUT variables to override defaults)"
	@echo "  validate          - Validate the schema.yaml file using mpdev validate"
	@echo "  help              - Display this help message"
