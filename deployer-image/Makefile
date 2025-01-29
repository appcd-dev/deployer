# Paths and binaries
BIN_DIR := $(HOME)/bin
MPDEV := $(BIN_DIR)/mpdev
SCHEMA_FILE := marketplace/schema.yaml
MANIFEST_DIR := marketplace/manifests

# Semantic minor version (TRACK) and full release version
# TODO(sabith) read from tag
TRACK ?= 1.1
RELEASE ?= ${TRACK}.0

# Docker registry and image names
REGISTRY = gcr.io/stackgen-gcp-marketplace
APP_NAME = stackgen-deployer
DEPLOYER_IMAGE_RELEASE := $(REGISTRY)/$(APP_NAME)/deployer:$(RELEASE)
DEPLOYER_IMAGE_TRACK := $(REGISTRY)/$(APP_NAME)/deployer:$(TRACK)

.PHONY: all push setup doctor install verify validate clean help

all: help

build:
	@gh_token=$(shell gh auth token) \
	docker buildx build \
	  --platform linux/amd64 \
	  --platform linux/arm64 \
	  --secret id=gh_token \
	  --annotation "com.googleapis.cloudmarketplace.product.service.name=services/stackgen-enterprise-platform-k8s-v2.endpoints.stackgen-gcp-marketplace.cloud.goog" \
	  -t $(DEPLOYER_IMAGE_RELEASE) \
	  -t $(DEPLOYER_IMAGE_TRACK) \
	  .
# Build, tag, and push the image in a single command
push: build
	docker push \
	  $(DEPLOYER_IMAGE_RELEASE)
	docker push \
	  $(DEPLOYER_IMAGE_TRACK)

setup:
	@echo "Setting up mpdev..."
	@mkdir -p $(BIN_DIR)
	@docker run gcr.io/cloud-marketplace-tools/k8s/dev cat /scripts/dev > $(MPDEV)
	@chmod +x $(MPDEV)
	@echo "mpdev installed at $(MPDEV)"

doctor:
	@echo "Running mpdev doctor..."
	@$(MPDEV) doctor

install:
	@echo "Installing application with deployer: $(DEPLOYER_IMAGE_RELEASE)"
	$(MPDEV) install \
	  --deployer=$(DEPLOYER_IMAGE_RELEASE)

verify: build
	@echo "Verifying application with deployer: $(DEPLOYER_IMAGE_RELEASE)"
	$(MPDEV) verify --deployer=$(DEPLOYER_IMAGE_RELEASE)

tofu: tofu/fmt

tofu/fmt:
	tofu fmt --recursive .

clean:
	@echo "Cleaning up Docker images..."
	docker rmi $(DEPLOYER_IMAGE_RELEASE) --force || true
	docker rmi $(DEPLOYER_IMAGE_TRACK) --force || true

help:
	@echo "Available targets:"
	@echo "  push      - Build, annotate, and push the image with RELEASE and TRACK tags"
	@echo "  setup     - Setup the mpdev tool"
	@echo "  doctor    - Diagnose your environment using mpdev doctor"
	@echo "  install   - Install an application using mpdev install"
	@echo "  verify    - Verify an application using mpdev verify"
	@echo "  validate  - Validate the deployer schema.yaml file"
	@echo "  clean     - Clean up local Docker images"
