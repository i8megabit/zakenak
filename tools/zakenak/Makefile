# Copyright (c) 2024 Mikhail Eberil
# Makefile for Ƶakenak™®

# Версия проекта
VERSION := 1.0.0
COMMIT := $(shell git rev-parse --short HEAD)
DATE := $(shell date -u '+%Y-%m-%d_%H:%M:%S')

# Переменные сборки
BINARY_NAME := zakenak
GO := go
DOCKER := docker
DOCKER_IMAGE := zakenak
DOCKER_TAG := $(VERSION)
REGISTRY_URL := registry.local

# Флаги сборки
LDFLAGS := -ldflags "-X main.Version=$(VERSION) -X main.Commit=$(COMMIT) -X main.BuildDate=$(DATE)"
GOFLAGS := -v

# Пути
SRC_DIR := ./src
BUILD_DIR := ./build
DOCS_DIR := ./docs

.PHONY: all build clean test docker-build docker-push install uninstall docs lint help

all: clean build test

build:
	@echo "Building Ƶakenak™®..."
	$(GO) build $(GOFLAGS) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) $(SRC_DIR)

clean:
	@echo "Cleaning..."
	rm -rf $(BUILD_DIR)
	$(GO) clean
	rm -f $(BINARY_NAME)

test:
	@echo "Running tests..."
	$(GO) test -v ./...

docker-build:
	@echo "Building Docker image..."
	$(DOCKER) build -t $(DOCKER_IMAGE):$(DOCKER_TAG) \
		--build-arg VERSION=$(VERSION) \
		--build-arg COMMIT=$(COMMIT) \
		--build-arg BUILD_DATE=$(DATE) .

docker-push:
	@echo "Pushing Docker image..."
	$(DOCKER) tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(REGISTRY_URL)/$(DOCKER_IMAGE):$(DOCKER_TAG)
	$(DOCKER) push $(REGISTRY_URL)/$(DOCKER_IMAGE):$(DOCKER_TAG)

install: build
	@echo "Installing Ƶakenak™®..."
	mv $(BUILD_DIR)/$(BINARY_NAME) /usr/local/bin/
	chmod +x /usr/local/bin/$(BINARY_NAME)

uninstall:
	@echo "Uninstalling Ƶakenak™®..."
	rm -f /usr/local/bin/$(BINARY_NAME)

docs:
	@echo "Generating documentation..."
	cd $(DOCS_DIR) && mkdocs build

lint:
	@echo "Running linters..."
	golangci-lint run
	
dev: build
	@echo "Starting development environment..."
	./$(BUILD_DIR)/$(BINARY_NAME)

help:
	@echo "Ƶakenak™® Makefile help:"
	@echo "make              - Build and test"
	@echo "make build        - Build binary"
	@echo "make clean        - Clean build artifacts"
	@echo "make test         - Run tests"
	@echo "make docker-build - Build Docker image"
	@echo "make docker-push  - Push Docker image"
	@echo "make install      - Install binary"
	@echo "make uninstall    - Uninstall binary"
	@echo "make docs         - Generate documentation"
	@echo "make lint         - Run linters"
	@echo "make dev          - Start development environment"