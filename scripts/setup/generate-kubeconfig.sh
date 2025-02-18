#!/bin/bash

# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# Script for generating kubeconfig for Zakenak

set -e

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Загрузка переменных окружения
source "${SCRIPT_DIR}/env.sh"

# Функция проверки ошибок
check_error() {
	if [ $? -ne 0 ]; then
		echo "Error: $1"
		exit 1
	fi
}

# Определение окружения
is_wsl() {
	grep -q "microsoft" /proc/version 2>/dev/null
	return $?
}

# Создание базовой конфигурации кластера
generate_kind_config() {
	local mounts=()
	
	if is_wsl; then
		echo "Generating WSL2 configuration..."
		mounts=("${WSL_MOUNTS[@]}")
	else
		echo "Generating Linux configuration..."
		mounts=("${LINUX_MOUNTS[@]}")
	fi
	
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
  - containerPort: ${INGRESS_HTTP_PORT}
    hostPort: ${INGRESS_HTTP_PORT}
    protocol: TCP
  - containerPort: ${INGRESS_HTTPS_PORT}
    hostPort: ${INGRESS_HTTPS_PORT}
    protocol: TCP
  extraMounts:
  # Путь к общим манифестам
  - hostPath: ./helm-charts/manifests
    containerPath: /etc/kubernetes/manifests
EOF

	# Добавление специфичных монтирований
	for mount in "${mounts[@]}"; do
		IFS=':' read -r host_path container_path <<< "$mount"
		echo "  - hostPath: $host_path" >> "${REPO_ROOT}/kind-config.yaml"
		echo "    containerPath: $container_path" >> "${REPO_ROOT}/kind-config.yaml"
	done

	check_error "Failed to generate kind config"
}

# Создание начального kubeconfig
generate_initial_kubeconfig() {
	# Принудительное создание/перезапись kubeconfig
	if [ -f "${REPO_ROOT}/kubeconfig.yaml" ]; then
		echo "Existing kubeconfig.yaml found, overwriting..."
		rm -f "${REPO_ROOT}/kubeconfig.yaml"
	fi

	cat > "${REPO_ROOT}/kubeconfig.yaml" << EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://kind-control-plane:6443
    insecure-skip-tls-verify: true
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
    client-certificate-data: ""
    client-key-data: ""
EOF
}

# Основная функция
main() {
	echo "Generating Kind configuration..."
	generate_kind_config
	
	echo "Generating initial kubeconfig..."
	generate_initial_kubeconfig
	
	echo "Configuration files generated successfully:"
	echo "- ${REPO_ROOT}/kind-config.yaml"
	echo "- ${REPO_ROOT}/kubeconfig.yaml"
	echo ""
	echo "You can now use these files to set up your cluster:"
	echo "1. Create cluster: kind create cluster --config kind-config.yaml"
	echo "2. Use kubeconfig: export KUBECONFIG=${REPO_ROOT}/kubeconfig.yaml"
}

main