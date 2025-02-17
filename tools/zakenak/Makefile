# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# 
# This file is part of Ƶakenak™® project.
# https://github.com/i8megabit/zakenak
#
# This program is free software and is released under the terms of the MIT License.
# See LICENSE.md file in the project root for full license information.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#
# TRADEMARK NOTICE:
# Ƶakenak™® and the Ƶakenak logo are registered trademarks of Mikhail Eberil.
# All rights reserved. The Ƶakenak trademark and brand may not be used in any way 
# without express written permission from the trademark owner.

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