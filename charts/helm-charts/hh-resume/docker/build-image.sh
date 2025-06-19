#!/bin/bash
set -e

# Configuration
IMAGE_NAME="ghcr.io/i8megabit/hh-resume-updater"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Checking if Docker image ${FULL_IMAGE_NAME} exists locally..."

# Check if image exists locally
if docker image inspect "${FULL_IMAGE_NAME}" &> /dev/null; then
    echo "Image ${FULL_IMAGE_NAME} already exists locally."
else
    echo "Image ${FULL_IMAGE_NAME} does not exist locally. Building..."
    
    # Build the image
    docker build -t "${FULL_IMAGE_NAME}" -f "${SCRIPT_DIR}/Dockerfile" "${SCRIPT_DIR}"
    
    echo "Image ${FULL_IMAGE_NAME} built successfully."
fi

echo "Docker image ${FULL_IMAGE_NAME} is ready to use."