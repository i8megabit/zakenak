#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

handle_error() {
    log_error "$1"
    exit 1
}

MODEL_NAME="deepseek-r1:14b-qwen-distill-q4_K_M"
OLLAMA_DIR="/mnt/o"

log_info "Setting up $MODEL_NAME model for Ollama"
echo "This script will help you set up the model after downloading it via Windows Ollama application."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    handle_error "Docker is not installed. Please install Docker first."
fi

# Check if Docker Compose is installed
if ! docker compose version &> /dev/null; then
    handle_error "Docker Compose V2 is not installed. Please install Docker Compose V2 first."
fi

# Check if the model directory exists
if [ ! -d "$OLLAMA_DIR" ]; then
    handle_error "The directory $OLLAMA_DIR does not exist. Please make sure it's mounted correctly."
fi

# Check if the model is already in the Ollama directory
MODEL_PATH="$OLLAMA_DIR/models"
if [ ! -d "$MODEL_PATH" ]; then
    log_warn "Models directory doesn't exist in $OLLAMA_DIR. Creating it..."
    mkdir -p "$MODEL_PATH"
fi

log_info "Checking if the model is already in the Ollama directory..."
if ls "$MODEL_PATH" | grep -q "$MODEL_NAME"; then
    log_info "Model $MODEL_NAME found in $MODEL_PATH."
else
    log_warn "Model $MODEL_NAME not found in $MODEL_PATH."
    log_warn "Please make sure you've downloaded the model using the Windows Ollama application."
    log_warn "Then copy the model files to $MODEL_PATH."
    exit 1
fi

# Set permissions to root:root
log_info "Setting permissions to root:root for the model files..."
sudo chown -R root:root "$MODEL_PATH"
sudo chmod -R 755 "$MODEL_PATH"

# Start Ollama container with GPU support
log_info "Starting Ollama container with GPU support..."
cd "$(dirname "$0")/docker-compose"
if ! docker compose up -d; then
    handle_error "Failed to start Ollama container. Check docker-compose logs."
fi

# Wait for Ollama to start
log_info "Waiting for Ollama to start..."
sleep 5

# Check if Ollama is running
MAX_RETRIES=12
RETRY_COUNT=0
OLLAMA_READY=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s http://localhost:11434/api/tags &> /dev/null; then
        OLLAMA_READY=true
        break
    fi
    
    log_warn "Waiting for Ollama to start... ($(($RETRY_COUNT + 1))/$MAX_RETRIES)"
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 5
done

if [ "$OLLAMA_READY" = false ]; then
    log_error "Ollama failed to start within the expected time. Please check the Docker logs:"
    echo "docker logs ollama"
    echo "If you see GPU-related errors, make sure your NVIDIA drivers and container toolkit are properly installed."
    exit 1
fi

# Check if the model is available in Ollama
log_info "Checking if the model is available in Ollama..."
if curl -s http://localhost:11434/api/tags | grep -q "$MODEL_NAME"; then
    log_info "Model $MODEL_NAME is available in Ollama."
else
    log_warn "Model $MODEL_NAME is not available in Ollama."
    log_warn "You may need to manually pull the model using:"
    log_warn "curl -X POST http://localhost:11434/api/pull -d '{\"name\":\"$MODEL_NAME\"}'"
fi

log_info "Setup complete!"
log_info "You can now use the model $MODEL_NAME with the optimized settings."
log_info "To test the model, you can run:"
log_info "curl -X POST http://localhost:11434/api/generate -d '{\"model\":\"$MODEL_NAME\",\"prompt\":\"Hello, how are you?\"}'"