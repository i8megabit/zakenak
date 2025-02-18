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