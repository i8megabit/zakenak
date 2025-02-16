# Copyright (c) 2024 Mikhail Eberil
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

.PHONY: all build clean test docker

all: clean build test

build:
	cd tools/zakenak && $(GO) build $(GOFLAGS) \
		-ldflags "-X main.Version=$(VERSION) -X main.BuildTime=$(BUILD_TIME)" \
		-o ../../bin/$(BINARY_NAME) ./cmd/$(BINARY_NAME)

test:
	cd tools/zakenak && $(GO) test -v ./...

clean:
	rm -rf bin/
	rm -f $(BINARY_NAME)

docker:
	docker buildx build \
		--platform linux/amd64 \
		--tag $(REGISTRY)/$(IMAGE_NAME):$(TAG) \
		--push \
		-f tools/zakenak/Dockerfile .

# Development helpers
dev-deps:
	$(GO) install golang.org/x/lint/golint@latest
	$(GO) install golang.org/x/tools/cmd/goimports@latest

lint:
	cd tools/zakenak && golint ./...
	cd tools/zakenak && go vet ./...
	cd tools/zakenak && goimports -w .

.DEFAULT_GOAL := build
