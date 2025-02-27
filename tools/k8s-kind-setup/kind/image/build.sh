#!/usr/bin/bash

# Set variables
IMAGE_NAME="kindest-node-gpu"
IMAGE_TAG="v1.27.3-gpu"

# Build the image
echo "Building custom KIND node image with GPU support..."
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

echo "Image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "You can use this image in your KIND configuration with:"
echo "kind: Cluster"
echo "apiVersion: kind.x-k8s.io/v1alpha4"
echo "nodes:"
echo "- role: control-plane"
echo "  image: ${IMAGE_NAME}:${IMAGE_TAG}"