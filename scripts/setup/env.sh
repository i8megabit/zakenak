#!/bin/bash

# Цвета для вывода
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export CYAN='\033[0;36m'
export NC='\033[0m'

# Версии компонентов
export KUBERNETES_VERSION="1.27.3"
export CUDA_VERSION="12.8"
export NVIDIA_DRIVER_VERSION="535.104.05"

# Пути
export KUBECONFIG="${HOME}/.kube/config"

# Kubernetes конфигурация
export CLUSTER_NAME="kind-zakenak"
export WSL_MOUNTS=(
	"/usr/lib/wsl/lib:/usr/lib/wsl/lib"
	"/usr/local/cuda-12.8:/usr/local/cuda-12.8"
	"/usr/local/cuda:/usr/local/cuda"
	"/usr/lib/wsl/lib/libcuda.so.1:/usr/lib/wsl/lib/libcuda.so.1"
	"/usr/lib/wsl/lib/libnvidia-ml.so.1:/usr/lib/wsl/lib/libnvidia-ml.so.1"
	"/dev/nvidia0:/dev/nvidia0"
	"/dev/nvidiactl:/dev/nvidiactl"
	"/dev/nvidia-uvm:/dev/nvidia-uvm"
	"/dev/nvidia-uvm-tools:/dev/nvidia-uvm-tools"
	"/dev/nvidia-modeset:/dev/nvidia-modeset"
)

export LINUX_MOUNTS=(
	"/usr/local/cuda-12.8:/usr/local/cuda-12.8"
	"/usr/local/cuda:/usr/local/cuda"
	"/dev/nvidia0:/dev/nvidia0"
	"/dev/nvidiactl:/dev/nvidiactl"
	"/dev/nvidia-uvm:/dev/nvidia-uvm"
	"/dev/nvidia-modeset:/dev/nvidia-modeset"
)