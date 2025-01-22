TESTER_IMAGE ?= gcr.io/platform-439702/tester:latest

build-tester:
	@echo "Building tester image..."
	@docker build -f Dockerfile -t $(TESTER_IMAGE) .

push-tester:
	@echo "Pushing tester image..."
	@docker push $(TESTER_IMAGE)
