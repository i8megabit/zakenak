# Build variables
REGISTRY ?= ghcr.io
IMAGE_NAME ?= i8megabit/gitops
GIT_SHA := $(shell git rev-parse --short HEAD)
VERSION ?= $(GIT_SHA)

# Go build flags
GOOS ?= linux
GOARCH ?= amd64
GO_BUILD_FLAGS := -v

.PHONY: all
all: build test

.PHONY: build
build:
	go build $(GO_BUILD_FLAGS) ./...

.PHONY: test
test:
	go test -v ./...

.PHONY: docker-build
docker-build:
	docker build -t $(REGISTRY)/$(IMAGE_NAME):$(VERSION) .
	docker tag $(REGISTRY)/$(IMAGE_NAME):$(VERSION) $(REGISTRY)/$(IMAGE_NAME):latest

.PHONY: docker-push
docker-push:
	docker push $(REGISTRY)/$(IMAGE_NAME):$(VERSION)
	docker push $(REGISTRY)/$(IMAGE_NAME):$(VERSION):latest

.PHONY: deploy
deploy:
	kubectl apply -f helm-charts/