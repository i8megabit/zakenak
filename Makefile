# Copyright (c) 2024 Mikhail Eberil
#
# This file is part of Zakenak project and is released under the terms of the
# MIT License. See LICENSE file in the project root for full license information.

BINARY_NAME=zakenak
VERSION=1.3.1
BUILD_DIR=build
INSTALL_DIR=/usr/local/bin

GO_FILES=$(shell find . -name '*.go' -not -path "./vendor/*")
LDFLAGS=-ldflags "-X main.Version=$(VERSION)"

.PHONY: all build clean install uninstall test lint

all: clean build

init:
	@echo "Initializing module..."
	@go mod tidy
	@go mod download

build: init
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