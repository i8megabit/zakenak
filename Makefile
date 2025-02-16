# Copyright (c) 2024 Mikhail Eberil
#
# This file is part of Zakenak project and is released under the terms of the
# MIT License. See LICENSE file in the project root for full license information.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#
# The name "Zakenak" and associated branding are trademarks of @eberil
# and may not be used without express written permission.

BINARY_NAME=zakenak
VERSION=1.3.1
BUILD_DIR=build
INSTALL_DIR=/usr/local/bin

GO_FILES=$(shell find . -name '*.go' -not -path "./vendor/*")
LDFLAGS=-ldflags "-X main.Version=$(VERSION)"

.PHONY: all build clean install uninstall test lint

all: clean build

build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	@go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) ./cmd/zakenak
	@echo "Build complete!"

clean:
	@echo "Cleaning..."
	@rm -rf $(BUILD_DIR)
	@go clean
	@echo "Clean complete!"

install: build
	@echo "Installing $(BINARY_NAME)..."
	@sudo cp $(BUILD_DIR)/$(BINARY_NAME) $(INSTALL_DIR)/$(BINARY_NAME)
	@sudo chmod +x $(INSTALL_DIR)/$(BINARY_NAME)
	@echo "Installation complete!"

uninstall:
	@echo "Uninstalling $(BINARY_NAME)..."
	@sudo rm -f $(INSTALL_DIR)/$(BINARY_NAME)
	@echo "Uninstallation complete!"

test:
	@echo "Running tests..."
	@go test -v ./...
	@echo "Tests complete!"

lint:
	@echo "Running linter..."
	@golangci-lint run
	@echo "Lint complete!"

# GPU-specific targets
gpu-check:
	@echo "Checking GPU requirements..."
	@nvidia-smi > /dev/null 2>&1 || (echo "Error: NVIDIA GPU not found or driver not installed" && exit 1)
	@command -v nvcc > /dev/null 2>&1 || (echo "Error: CUDA toolkit not found" && exit 1)
	@echo "GPU check passed!"

gpu-build: gpu-check build

# Development helpers
dev-setup:
	@echo "Setting up development environment..."
	@go mod download
	@go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@echo "Dev setup complete!"

# Release helpers
release:
	@echo "Creating release $(VERSION)..."
	@git tag -a v$(VERSION) -m "Release v$(VERSION)"
	@git push origin v$(VERSION)
	@echo "Release complete!"
