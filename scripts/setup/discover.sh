#!/bin/bash

# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# Script for auto-discovering system configuration

# Функция определения версии Kubernetes
discover_kubernetes_version() {
	local latest_version
	latest_version=$(curl -s https://api.github.com/repos/kubernetes/kubernetes/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
	echo "${latest_version#v}"
}

# Функция определения GPU параметров
discover_gpu_config() {
	if command -v nvidia-smi &> /dev/null; then
		local gpu_info="GPU_AVAILABLE=true"
		gpu_info+=",GPU_COUNT=$(nvidia-smi --query-gpu=gpu_name --format=csv,noheader | wc -l)"
		gpu_info+=",GPU_MEMORY=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader | head -n1 | cut -d' ' -f1)"
		gpu_info+=",CUDA_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n1)"
		gpu_info+=",COMPUTE_CAPABILITY=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader | head -n1)"
		echo "$gpu_info"
	else
		echo "GPU_AVAILABLE=false,GPU_COUNT=0,GPU_MEMORY=0,CUDA_VERSION=none,COMPUTE_CAPABILITY=none"
	fi
}

# Функция определения параметров безопасности
discover_security_config() {
	local user_id=$(id -u)
	local user_name=$(id -un)
	local security_config="user_id=$user_id user_name=$user_name"
	security_config+=" pids_limit=100"
	security_config+=" cpu_limit=2.0"
	security_config+=" memory_limit=8G"
	security_config+=" io_limit=1mb"
	security_config+=" gpu_memory_limit=8Gi"
	security_config+=" gpu_usage_threshold=95"
	security_config+=" audit_level=RequestResponse"
	echo "$security_config"
}

# Функция обнаружения GPU устройств и путей
discover_gpu_mounts() {
	local mounts=()
	
	# Поиск CUDA installation
	local cuda_paths=($(find /usr/local -maxdepth 1 -name "cuda*" -type d 2>/dev/null))
	for path in "${cuda_paths[@]}"; do
		mounts+=("${path}:${path}")
	done
	
	# Поиск NVIDIA devices
	for dev in /dev/nvidia*; do
		if [ -e "$dev" ]; then
			mounts+=("${dev}:${dev}")
		fi
	done
	
	# WSL specific paths
	if grep -q microsoft /proc/version; then
		if [ -d "/usr/lib/wsl" ]; then
			mounts+=("/usr/lib/wsl/lib:/usr/lib/wsl/lib")
			if [ -f "/usr/lib/wsl/lib/libcuda.so.1" ]; then
				mounts+=("/usr/lib/wsl/lib/libcuda.so.1:/usr/lib/wsl/lib/libcuda.so.1")
			fi
			if [ -f "/usr/lib/wsl/lib/libnvidia-ml.so.1" ]; then
				mounts+=("/usr/lib/wsl/lib/libnvidia-ml.so.1:/usr/lib/wsl/lib/libnvidia-ml.so.1")
			fi
		fi
	fi
	
	echo "${mounts[@]}"
}

# Функция определения доступных портов
discover_available_ports() {
	local http_port=80
	local https_port=443
	
	# Проверка занятости портов
	while lsof -i:${http_port} >/dev/null 2>&1; do
		http_port=$((http_port + 1))
	done
	
	while lsof -i:${https_port} >/dev/null 2>&1; do
		https_port=$((https_port + 1))
	done
	
	echo "${http_port} ${https_port}"
}

# Функция обнаружения Helm чартов
discover_helm_charts() {
	local repo_root="$1"
	local charts_dir="${repo_root}/helm-charts"
	local charts=()
	
	if [ -d "$charts_dir" ]; then
		for chart in "$charts_dir"/*; do
			if [ -d "$chart" ]; then
				local chart_name=$(basename "$chart")
				local values=()
				
				# Проверка наличия values файлов
				if [ -f "$chart/values.yaml" ]; then
					values+=("values.yaml")
				fi
				if [ -f "$chart/values-prod.yaml" ]; then
					values+=("values-prod.yaml")
				fi
				if [ -f "$chart/values-gpu.yaml" ]; then
					values+=("values-gpu.yaml")
				fi
				
				charts+=("$chart_name:${values[*]}")
			fi
		done
	fi
	echo "${charts[*]}"
}

# Функция определения системных ресурсов
discover_system_resources() {
	echo "cpu_count=$(nproc) memory_total=$(free -g | awk '/^Mem:/{print $2}') storage_root=$(df -h / | awk 'NR==2 {print $4}')"
}

# Функция определения Docker параметров
discover_docker_config() {
	if command -v docker &> /dev/null; then
		echo "version=$(docker version --format '{{.Server.Version}}') root_dir=$(docker info --format '{{.DockerRootDir}}') security_options=$(docker info --format '{{.SecurityOptions}}')"
	else
		echo "version=none root_dir=none security_options=none"
	fi
}

# Экспорт всех обнаруженных параметров
export_discovered_values() {
	local repo_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
	local k8s_version=$(discover_kubernetes_version)
	local gpu_config=$(discover_gpu_config)
	local security_config=$(discover_security_config)
	local system_resources=$(discover_system_resources)
	local docker_config=$(discover_docker_config)
	local gpu_mounts=($(discover_gpu_mounts))
	local helm_charts=$(discover_helm_charts "$repo_root")
	read -r http_port https_port <<< "$(discover_available_ports)"
	
	cat << EOF
# Auto-discovered configuration $(date)
export KUBERNETES_VERSION="${k8s_version}"

# GPU Configuration
export GPU_AVAILABLE=$(echo "$gpu_config" | cut -d',' -f1 | cut -d'=' -f2)
export GPU_COUNT=$(echo "$gpu_config" | cut -d',' -f2 | cut -d'=' -f2)
export GPU_MEMORY=$(echo "$gpu_config" | cut -d',' -f3 | cut -d'=' -f2)
export CUDA_VERSION=$(echo "$gpu_config" | cut -d',' -f4 | cut -d'=' -f2)
export COMPUTE_CAPABILITY=$(echo "$gpu_config" | cut -d',' -f5 | cut -d'=' -f2)

# Security Configuration
export SECURITY_USER_ID=$(echo "$security_config" | cut -d' ' -f1 | cut -d'=' -f2)
export SECURITY_USER_NAME=$(echo "$security_config" | cut -d' ' -f2 | cut -d'=' -f2)
export DEFAULT_PIDS_LIMIT=$(echo "$security_config" | cut -d' ' -f3 | cut -d'=' -f2)
export DEFAULT_CPU_LIMIT=$(echo "$security_config" | cut -d' ' -f4 | cut -d'=' -f2)
export DEFAULT_MEMORY_LIMIT=$(echo "$security_config" | cut -d' ' -f5 | cut -d'=' -f2)
export DEFAULT_IO_LIMIT=$(echo "$security_config" | cut -d' ' -f6 | cut -d'=' -f2)
export DEFAULT_GPU_MEMORY_LIMIT=$(echo "$security_config" | cut -d' ' -f7 | cut -d'=' -f2)
export DEFAULT_GPU_USAGE_THRESHOLD=$(echo "$security_config" | cut -d' ' -f8 | cut -d'=' -f2)
export DEFAULT_AUDIT_LEVEL=$(echo "$security_config" | cut -d' ' -f9 | cut -d'=' -f2)

# System Resources
export CPU_COUNT=$(echo "$system_resources" | cut -d' ' -f1 | cut -d'=' -f2)
export MEMORY_TOTAL=$(echo "$system_resources" | cut -d' ' -f2 | cut -d'=' -f2)
export STORAGE_ROOT=$(echo "$system_resources" | cut -d' ' -f3 | cut -d'=' -f2)

# Docker Configuration
export DOCKER_VERSION=$(echo "$docker_config" | cut -d' ' -f1 | cut -d'=' -f2)
export DOCKER_ROOT_DIR=$(echo "$docker_config" | cut -d' ' -f2 | cut -d'=' -f2)
export DOCKER_SECURITY_OPTIONS=$(echo "$docker_config" | cut -d' ' -f3 | cut -d'=' -f2)

# Network Configuration
export DEFAULT_DNS_SERVERS='8.8.8.8 8.8.4.4'
export DEFAULT_NETWORK_NAME=zakenak-network
export DEFAULT_NETWORK_DRIVER=bridge

# Logging Paths
export LOG_DIR=/var/log/zakenak
export AUDIT_LOG_PATH=/var/log/zakenak/audit.log
export GPU_METRICS_LOG=/var/log/zakenak/gpu-metrics.log

# Image Configuration
export ZAKENAK_IMAGE=ghcr.io/i8megabit/zakenak
export ZAKENAK_VERSION=latest

# Other Configuration
export HELM_CHARTS="$helm_charts"
export INGRESS_HTTP_PORT=${http_port}
export INGRESS_HTTPS_PORT=${https_port}

# GPU Mounts
export WSL_MOUNTS=(
$(for mount in "${gpu_mounts[@]}"; do echo "    \"${mount}\""; done)
)

export LINUX_MOUNTS=(
$(for mount in "${gpu_mounts[@]}"; do echo "    \"${mount}\""; done)
)
EOF
}

# Если скрипт запущен напрямую
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
	export_discovered_values "$REPO_ROOT"
fi