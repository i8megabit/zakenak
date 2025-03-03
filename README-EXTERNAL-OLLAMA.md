# External Ollama with GPU for Kubernetes

This guide explains how to set up Ollama with GPU support in a Docker container outside of Kubernetes, and configure your Kubernetes cluster to use this external Ollama instance.

## Overview

Instead of running Ollama with GPU resources directly in Kubernetes pods, this setup:

1. Runs Ollama in a Docker container with GPU access using Docker Compose
2. Creates a Kubernetes service that points to the external Ollama container
3. Maintains integration with Open WebUI in the Kubernetes cluster

This approach allows you to:
- Use GPU resources more efficiently
- Simplify Kubernetes resource management (no GPU resources needed in K8s)
- Maintain the same user experience with Open WebUI

## Setup Instructions

### Automated Setup (Recommended)

The easiest way to set up this configuration is to use the provided setup script:

```bash
./setup-external-ollama.sh
```

This script will:
1. Check for required dependencies (Docker, Docker Compose, kubectl, Helm, NVIDIA drivers)
2. Install NVIDIA Container Toolkit if needed
3. Start the Ollama container with GPU support using Docker Compose
4. Create a Kubernetes service that points to the external Ollama container
5. Deploy the Open WebUI Helm chart with the appropriate configuration
6. Wait for the Open WebUI pod to become ready (may take up to 30 minutes)

### Manual Setup

If you prefer to set up the components manually:

#### 1. Set up Ollama in Docker

Navigate to the `docker-compose` directory and start Ollama with GPU support:

```bash
cd docker-compose
docker compose up -d
```

#### 2. Create Kubernetes Service for External Ollama

Create a Kubernetes service that points to the external Ollama container:

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

#### 3. Deploy Open WebUI

Deploy the Open WebUI Helm chart with GPU configuration disabled:

```bash
helm upgrade --install open-webui ./helm-charts/open-webui -n prod --set deployment.gpuConfig=false
```

## Troubleshooting

If Open WebUI cannot connect to Ollama, check the following:

1. Ensure the Ollama container is running in Docker:
   ```bash
   docker ps | grep ollama
   docker logs ollama
   ```

2. Verify that the Ollama service in Kubernetes is correctly configured:
   ```bash
   kubectl get svc -n prod ollama
   ```

3. Test connectivity from within the Kubernetes cluster:
   ```bash
   kubectl run -it --rm debug --image=curlimages/curl -- curl http://host.docker.internal:11434/api/tags
   ```

4. Check the logs of the Open WebUI pod:
   ```bash
   kubectl logs -n prod -l app=open-webui
   ```

5. Check the status of the Open WebUI pod:
   ```bash
   kubectl describe pod -n prod -l app=open-webui
   ```

6. If you're using a different hostname than `host.docker.internal`, make sure it's correctly set in the Kubernetes service.

7. For segmentation faults (exit code 139), try increasing the memory limits in the Open WebUI Helm chart:
   ```bash
   helm upgrade --install open-webui ./helm-charts/open-webui -n prod --set deployment.gpuConfig=false --set deployment.resources.limits.memory=4Gi
   ```

## Network Configuration

For this setup to work, your Kubernetes cluster needs to be able to communicate with the Docker host. If you're using Kind or Minikube on the same machine, this should work automatically using `host.docker.internal` as the hostname.

If you're using a different setup, you may need to adjust the hostname in the Kubernetes service to point to the correct IP address of your Docker host.

## Startup Time

The Open WebUI pod may take up to 30 minutes to start up completely. The startup probe is configured with extended timeouts to allow sufficient time for the container to become ready. If the pod is still not ready after this time, check the logs for any errors.

The startup process includes:
- Database initialization and migrations
- Loading models and resources
- Establishing connection to Ollama

During this time, the pod will show as "Running" but not "Ready" until all health checks pass.