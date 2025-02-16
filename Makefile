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

# Directories
CMD_DIR := ./cmd/gitops
BUILD_DIR := ./build

.PHONY: all
all: clean build test

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)

.PHONY: build
build: clean
	$(GO) mod tidy
	CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) $(GO) build \
		$(GO_BUILD_FLAGS) \
		-ldflags "-X main.Version=$(VERSION) -X main.Commit=$(COMMIT) -X main.BuildDate=$(BUILD_DATE)" \
		-o $(BUILD_DIR)/gitops $(CMD_DIR)

.PHONY: test
test:
	$(GO) test -v ./...

.PHONY: docker-build
docker-build:
	docker build -t $(REGISTRY)/$(IMAGE_NAME):$(VERSION) .
	docker tag $(REGISTRY)/$(IMAGE_NAME):$(VERSION) $(REGISTRY)/$(IMAGE_NAME):latest

.PHONY: docker-push
docker-push:
	docker push $(REGISTRY)/$(IMAGE_NAME):$(VERSION)
	docker push $(REGISTRY)/$(IMAGE_NAME):latest

.PHONY: deploy
deploy:
	kubectl apply -f helm-charts/
