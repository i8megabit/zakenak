#!/bin/bash

# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# Script for generating kubeconfig for Zakenak

set -e

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Функция проверки ошибок
check_error() {
	if [ $? -ne 0 ]; then
		echo "Error: $1"
		exit 1
	fi
}

# Создание базовой конфигурации кластера
generate_kind_config() {
	cat > "${REPO_ROOT}/kind-config.yaml" << EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
	kind: InitConfiguration
	nodeRegistration:
	  kubeletExtraArgs:
		node-labels: "ingress-ready=true,nvidia.com/gpu=present"
  extraPortMappings:
  - containerPort: 80
	hostPort: 80
	protocol: TCP
  - containerPort: 443
	hostPort: 443
	protocol: TCP
  extraMounts:
  # Путь к общим манифестам
  - hostPath: ./helm-charts/manifests
	containerPath: /etc/kubernetes/manifests
  # WSL2 specific NVIDIA paths
  - hostPath: /usr/lib/wsl/lib
	containerPath: /usr/lib/wsl/lib
  # CUDA toolkit
  - hostPath: /usr/local/cuda-12.8
	containerPath: /usr/local/cuda-12.8
  - hostPath: /usr/local/cuda
	containerPath: /usr/local/cuda
  # NVIDIA драйверы и библиотеки для WSL2
  - hostPath: /usr/lib/wsl/lib/libcuda.so.1
	containerPath: /usr/lib/wsl/lib/libcuda.so.1
  - hostPath: /usr/lib/wsl/lib/libnvidia-ml.so.1
	containerPath: /usr/lib/wsl/lib/libnvidia-ml.so.1
  # NVIDIA устройства
  - hostPath: /dev/nvidia0
	containerPath: /dev/nvidia0
  - hostPath: /dev/nvidiactl
	containerPath: /dev/nvidiactl
  - hostPath: /dev/nvidia-uvm
	containerPath: /dev/nvidia-uvm
  - hostPath: /dev/nvidia-uvm-tools
	containerPath: /dev/nvidia-uvm-tools
  - hostPath: /dev/nvidia-modeset
	containerPath: /dev/nvidia-modeset
EOF
	check_error "Failed to generate kind config"
}

# Получение данных из текущего контекста
get_cluster_data() {
	CURRENT_CONTEXT=$(kubectl config current-context)
	check_error "Failed to get current context"
	
	CLUSTER_NAME="kind-zakenak"
	CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
	check_error "Failed to get cluster server"
	
	CA_DATA=$(kubectl config view --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
	check_error "Failed to get CA data"
	
	CLIENT_CERT_DATA=$(kubectl config view --minify --flatten -o jsonpath='{.users[0].user.client-certificate-data}')
	check_error "Failed to get client cert data"
	
	CLIENT_KEY_DATA=$(kubectl config view --minify --flatten -o jsonpath='{.users[0].user.client-key-data}')
	check_error "Failed to get client key data"
}

# Создание kubeconfig
generate_kubeconfig() {
	cat > "${REPO_ROOT}/kubeconfig.yaml" << EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
	server: ${CLUSTER_SERVER}
	certificate-authority-data: ${CA_DATA}
  name: ${CLUSTER_NAME}
contexts:
- context:
	cluster: ${CLUSTER_NAME}
	user: ${CLUSTER_NAME}
  name: ${CLUSTER_NAME}
current-context: ${CLUSTER_NAME}
preferences: {}
users:
- name: ${CLUSTER_NAME}
  user:
	client-certificate-data: ${CLIENT_CERT_DATA}
	client-key-data: ${CLIENT_KEY_DATA}
EOF
	check_error "Failed to generate kubeconfig"
}

# Основная функция
main() {
	echo "Generating Kind configuration..."
	generate_kind_config
	
	echo "Getting cluster data..."
	get_cluster_data
	
	echo "Generating kubeconfig..."
	generate_kubeconfig
	
	echo "Configuration files generated successfully:"
	echo "- ${REPO_ROOT}/kind-config.yaml"
	echo "- ${REPO_ROOT}/kubeconfig.yaml"
	echo ""
	echo "You can now use these files to set up your cluster:"
	echo "1. Create cluster: kind create cluster --config kind-config.yaml"
	echo "2. Use kubeconfig: export KUBECONFIG=${REPO_ROOT}/kubeconfig.yaml"
}

main