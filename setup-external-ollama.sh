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

log_info "Setting up External Ollama with GPU for Kubernetes"
echo "This script will help you set up Ollama with GPU support in Docker and configure Kubernetes to use it."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    handle_error "Docker is not installed. Please install Docker first."
fi

# Check if Docker Compose is installed
if ! docker compose version &> /dev/null; then
    handle_error "Docker Compose V2 is not installed. Please install Docker Compose V2 first."
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    handle_error "kubectl is not installed. Please install kubectl first."
fi

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    handle_error "Helm is not installed. Please install Helm first."
fi

# Check if NVIDIA Container Toolkit is installed
log_warn "Checking if NVIDIA Container Toolkit is installed..."
if ! command -v nvidia-smi &> /dev/null; then
    handle_error "NVIDIA drivers are not installed. Please install NVIDIA drivers first."
fi

if ! command -v nvidia-container-cli &> /dev/null; then
    log_warn "NVIDIA Container Toolkit is not installed. Installing..."
    
    # Install NVIDIA Container Toolkit
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    if ! curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -; then
        handle_error "Failed to add NVIDIA GPG key."
    fi
    
    if ! curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list; then
        handle_error "Failed to add NVIDIA repository."
    fi
    
    if ! sudo apt-get update; then
        handle_error "Failed to update package lists."
    fi
    
    if ! sudo apt-get install -y nvidia-container-toolkit; then
        handle_error "Failed to install NVIDIA Container Toolkit."
    fi
    
    # Configure Docker to use NVIDIA Container Toolkit
    if ! sudo nvidia-ctk runtime configure --runtime=docker; then
        handle_error "Failed to configure Docker runtime for NVIDIA."
    fi
    
    if ! sudo systemctl restart docker; then
        handle_error "Failed to restart Docker service."
    fi
    
    log_info "NVIDIA Container Toolkit installed and configured."
else
    log_info "NVIDIA Container Toolkit is already installed."
fi

# Start Ollama container with GPU support
log_warn "Starting Ollama container with GPU support..."
if [ ! -d "docker-compose" ]; then
    handle_error "docker-compose directory not found. Please make sure you're in the correct directory."
fi

cd docker-compose
if ! docker compose up -d; then
    handle_error "Failed to start Ollama container. Check docker-compose logs."
fi
cd ..

# Wait for Ollama to start
log_warn "Waiting for Ollama to start..."
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

log_info "Ollama is running with GPU support."

# Create namespace if it doesn't exist
if ! kubectl get namespace prod &> /dev/null; then
    log_warn "Creating namespace 'prod'..."
    if ! kubectl create namespace prod; then
        handle_error "Failed to create namespace 'prod'."
    fi
    log_info "Namespace 'prod' created successfully."
else
    log_info "Namespace 'prod' already exists."
fi

# Create Kubernetes service for external Ollama
log_warn "Creating Kubernetes service for external Ollama..."
if ! kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ollama
  namespace: prod
  labels:
    app: ollama
spec:
  type: ExternalName
  externalName: host.docker.internal
  ports:
    - port: 11434
      targetPort: 11434
      protocol: TCP
      name: http
EOF
then
    handle_error "Failed to create Ollama service."
fi

# Verify that the service was created successfully
if ! kubectl get service ollama -n prod &> /dev/null; then
    handle_error "Failed to create Ollama service. Please check kubectl logs."
fi

log_info "Ollama service created successfully."

# Test connectivity to Ollama from within Kubernetes
log_warn "Testing connectivity to Ollama from within Kubernetes..."
if ! kubectl run -it --rm --restart=Never debug --image=curlimages/curl -- curl -s --connect-timeout 5 http://ollama.prod.svc.cluster.local:11434/api/tags &> /dev/null; then
    log_warn "Failed to connect to Ollama from within Kubernetes."
    log_warn "This could be due to networking issues between Kubernetes and the Docker host."
    log_warn "Make sure 'host.docker.internal' resolves correctly from within your Kubernetes cluster."
    log_warn "If you're using Kind or Minikube, you may need to add extra configuration."
    log_warn "Continuing with setup, but Open WebUI may not be able to connect to Ollama."
else
    log_info "Successfully connected to Ollama from within Kubernetes."
fi

# Deploy Open WebUI Helm chart
log_warn "Deploying Open WebUI Helm chart..."
if ! helm upgrade --install open-webui ./helm-charts/open-webui -n prod --set deployment.gpuConfig=false; then
    handle_error "Failed to deploy Open WebUI Helm chart."
fi

log_warn "Waiting for Open WebUI to start (this may take up to 60 minutes)..."
log_warn "The startup probe allows up to 60 minutes for the container to become ready."

# Wait for Open WebUI pod to be ready (with a timeout)
timeout=3600  # 60 minutes (to match the increased startup probe configuration)
start_time=$(date +%s)
pod_ready=false

while true; do
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    
    if [ $elapsed -gt $timeout ]; then
        log_error "Timed out waiting for Open WebUI pod to be ready."
        log_warn "You can check the pod status with:"
        log_warn "kubectl get pods -n prod"
        log_warn "kubectl describe pod -n prod -l app=open-webui"
        log_warn "kubectl logs -n prod -l app=open-webui"
        break
    fi
    
    pod_status=$(kubectl get pods -n prod -l app=open-webui -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
    
    if [ "$pod_status" == "Running" ]; then
        ready_status=$(kubectl get pods -n prod -l app=open-webui -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
        if [ "$ready_status" == "true" ]; then
            log_info "Open WebUI is running and ready!"
            pod_ready=true
            break
        fi
    fi
    
    # Check for container crashes
    restart_count=$(kubectl get pods -n prod -l app=open-webui -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}' 2>/dev/null || echo "0")
    # Ensure restart_count is a valid integer
    if [[ ! "$restart_count" =~ ^[0-9]+$ ]]; then
        restart_count=0
    fi

    if [ $restart_count -gt 3 ]; then
        log_error "Open WebUI container has crashed multiple times. Checking logs..."
        kubectl logs -n prod -l app=open-webui
        log_warn "You may need to adjust memory limits or check for other issues."
    fi
    
    log_warn "Waiting for Open WebUI pod to be ready... (${elapsed}s elapsed)"
    sleep 10
done

if [ "$pod_ready" = true ]; then
    log_info "Setup complete!"
    echo -e "You can access Open WebUI at: ${YELLOW}http://webui.prod.local${NC}"
    echo -e "Make sure to add the following entry to your /etc/hosts file:"
    echo -e "${YELLOW}127.0.0.1 webui.prod.local${NC}"
    echo -e "To test the connection from within Kubernetes, run:"
    echo -e "${YELLOW}kubectl run -it --rm debug --image=curlimages/curl -- curl http://host.docker.internal:11434/api/tags${NC}"
    echo -e "To check the Open WebUI logs, run:"
    echo -e "${YELLOW}kubectl logs -n prod -l app=open-webui${NC}"
else
    log_warn "Setup completed with warnings. Open WebUI may not be fully ready."
    echo -e "You can still try to access Open WebUI at: ${YELLOW}http://webui.prod.local${NC}"
    echo -e "Make sure to add the following entry to your /etc/hosts file:"
    echo -e "${YELLOW}127.0.0.1 webui.prod.local${NC}"
    echo -e "To troubleshoot issues:"
    echo -e "1. Check if Ollama is running: ${YELLOW}docker logs ollama${NC}"
    echo -e "2. Check if the service is created: ${YELLOW}kubectl get svc -n prod ollama${NC}"
    echo -e "3. Check Open WebUI pod status: ${YELLOW}kubectl describe pod -n prod -l app=open-webui${NC}"
    echo -e "4. Check Open WebUI logs: ${YELLOW}kubectl logs -n prod -l app=open-webui${NC}"
    echo -e "5. Check network connectivity: ${YELLOW}kubectl run -it --rm debug --image=curlimages/curl -- curl http://host.docker.internal:11434/api/tags${NC}"
    echo -e "6. Verify Docker Compose logs: ${YELLOW}cd docker-compose && docker compose logs${NC}"
fi