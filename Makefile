# Copyright (c) 2024 Mikhail Eberil
# Configuration file for Ƶakenak™®

# Build variables
REGISTRY ?= ghcr.io
IMAGE_NAME ?= i8megabit/gitops
VERSION ?= $(shell git describe --tags --always --dirty)
COMMIT ?= $(shell git rev-parse --short HEAD)
BUILD_DATE ?= $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')

# Go build settings
GO := go
GOOS ?= linux
GOARCH ?= amd64
CGO_ENABLED ?= 0
GO_BUILD_FLAGS := -v
GO_TEST_FLAGS := -v -race -coverprofile=coverage.out

# Directories
CMD_DIR := ./cmd/gitops
BUILD_DIR := ./build
HELM_CHARTS_DIR := ./helm-charts

# Docker settings
DOCKER_BUILD_ARGS := \
	--build-arg VERSION=$(VERSION) \
	--build-arg COMMIT=$(COMMIT) \
	--build-arg BUILD_DATE=$(BUILD_DATE)

.PHONY: all
all: clean build test

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)

.PHONY: build
build: clean
	CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) $(GO) build \
		$(GO_BUILD_FLAGS) \
		-ldflags "-X main.Version=$(VERSION) -X main.Commit=$(COMMIT) -X main.BuildDate=$(BUILD_DATE)" \
		-o $(BUILD_DIR)/gitops $(CMD_DIR)

.PHONY: test
test:
	$(GO) test $(GO_TEST_FLAGS) ./...
	$(GO) tool cover -func=coverage.out

.PHONY: lint
lint:
	golangci-lint run

.PHONY: docker-build
docker-build:
	docker build $(DOCKER_BUILD_ARGS) -t $(REGISTRY)/$(IMAGE_NAME):$(VERSION) .
	docker tag $(REGISTRY)/$(IMAGE_NAME):$(VERSION) $(REGISTRY)/$(IMAGE_NAME):latest

.PHONY: docker-push
docker-push:
	docker push $(REGISTRY)/$(IMAGE_NAME):$(VERSION)
	docker push $(REGISTRY)/$(IMAGE_NAME):latest

.PHONY: deploy
deploy:
	kubectl apply -f $(HELM_CHARTS_DIR)/install-order.yaml
	for chart in $$(yq e '.charts[]' $(HELM_CHARTS_DIR)/install-order.yaml); do \
		helm upgrade --install $$chart $(HELM_CHARTS_DIR)/$$chart --namespace prod --create-namespace; \
	done

.PHONY: fmt
fmt:
	$(GO) fmt ./...

.PHONY: mod-tidy
mod-tidy:
	$(GO) mod tidy

.PHONY: help
help:
	@echo "Ƶakenak™® Build System"
	@echo "Available targets:"
	@echo "  all          - Clean, build and test"
	@echo "  clean        - Remove build artifacts"
	@echo "  build        - Build the binary"
	@echo "  test         - Run tests with coverage"
	@echo "  lint         - Run linter"
	@echo "  docker-build - Build Docker image"
	@echo "  docker-push  - Push Docker image"
	@echo "  deploy       - Deploy to Kubernetes"
	@echo "  fmt          - Format Go code"
	@echo "  mod-tidy     - Tidy Go modules"