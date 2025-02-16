# Copyright (c)  2025 Mikhail Eberil
#
# This file is part of Zakenak project and is released under the terms of the
# MIT License. See LICENSE file in the project root for full license information.

SHELL := /bin/bash
GO := go
GOFLAGS := -v
BINARY_NAME := zakenak
VERSION := $(shell git describe --tags --always --dirty)
BUILD_TIME := $(shell date -u '+%Y-%m-%d_%H:%M:%S')

# Docker configuration
REGISTRY ?= ghcr.io
IMAGE_NAME ?= i8megabit/gitops
TAG ?= $(VERSION)

.PHONY: all build clean test docker deps tidy vendor init-modules

all: clean deps build test

# Initialize and update Go modules
init-modules:
	$(GO) mod init github.com/i8megabit/zakenak || true
	$(GO) mod tidy
	$(GO) mod download
	$(GO) mod verify

# Add explicit dependency management
deps: init-modules
	$(GO) mod download
	$(GO) mod verify
	$(GO) mod tidy

# Add vendor target for offline builds
vendor:
	$(GO) mod vendor

build: deps
	$(GO) build $(GOFLAGS) \
		-ldflags "-X main.Version=$(VERSION) -X main.BuildTime=$(BUILD_TIME)" \
		-o ../../bin/$(BINARY_NAME) ./cmd/$(BINARY_NAME)

test: deps
	$(GO) test -v ./...

clean:
	rm -rf bin/
	rm -f $(BINARY_NAME)
	rm -rf vendor/

docker:
	docker buildx build \
		--platform linux/amd64 \
		--tag $(REGISTRY)/$(IMAGE_NAME):$(TAG) \
		--push \
		.

# Development helpers
dev-deps:
	$(GO) install golang.org/x/lint/golint@latest
	$(GO) install golang.org/x/tools/cmd/goimports@latest

lint:
	golint ./...
	go vet ./...
	goimports -w .

.DEFAULT_GOAL := build