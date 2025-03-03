# Ollama Docker Compose Setup with GPU Support

This directory contains a Docker Compose configuration for running Ollama with GPU support outside of Kubernetes.

## Prerequisites

- Docker Engine 20.10.0 or later
- Docker Compose V2
- NVIDIA Container Toolkit installed and configured
- NVIDIA GPU with appropriate drivers

## Setup Instructions

### 1. Install NVIDIA Container Toolkit

Ensure the NVIDIA Container Toolkit is installed and configured:

```bash
# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit

# Configure Docker to use NVIDIA Container Toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### 2. Start Ollama with GPU Support

Start the Ollama container with GPU support:

```bash
docker compose up -d
```

### 3. Verify Ollama is Running

Verify that Ollama is running with GPU support:

```bash
curl http://localhost:11434/api/tags
```

You should see a JSON response with available models. If you see an empty list, it means Ollama is running but no models have been pulled yet.

To check if GPU is being used:

```bash
docker logs ollama | grep GPU
```

You should see output indicating that GPU resources are detected and being used.

## Integration with Kubernetes

To use this external Ollama instance with Kubernetes:

1. Create a Kubernetes service that points to the Docker host:

```bash
kubectl apply -f - <<EOF
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
```

2. Deploy Open WebUI configured to use this external Ollama service:

```bash
helm upgrade --install open-webui ../helm-charts/open-webui -n prod
```

## Configuration

The Docker Compose file includes the following configurations:

- Ollama container with GPU access
- Persistent volume for storing models
- Network configuration for external access
- Environment variables for optimal GPU usage

### Environment Variables

You can modify these environment variables in the Docker Compose file:

- `OLLAMA_HOST`: The host address to bind to (default: 0.0.0.0)
- `OLLAMA_COMPUTE_TYPE`: The compute type to use (default: gpu)
- `OLLAMA_GPU_LAYERS`: Number of layers to offload to GPU (default: 99)
- `OLLAMA_F16`: Whether to use FP16 precision (default: true)
- `OLLAMA_QUANTIZATION`: The quantization level to use (default: q4_0)
- `OLLAMA_CUDA_MEMORY_FRACTION`: Fraction of GPU memory to use (default: 0.95)
- `OLLAMA_CUDA_FORCE_ALLOCATION`: Whether to force memory allocation (default: true)

Note: The `OLLAMA_MODEL` environment variable has been removed to allow users to download and select models manually through the Open WebUI GUI.

## Troubleshooting

If you encounter issues:

1. Check if the Docker container is running:
   ```bash
   docker ps | grep ollama
   ```

2. Check the container logs:
   ```bash
   docker logs ollama
   ```

3. Verify GPU access:
   ```bash
   docker exec -it ollama nvidia-smi
   ```

4. Test the API:
   ```bash
   curl http://localhost:11434/api/tags
   ```

5. If Kubernetes cannot connect to the Docker host, try using the actual IP address of your host machine instead of `host.docker.internal` in the Kubernetes service.