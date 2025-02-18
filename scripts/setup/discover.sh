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
	local gpu_info
	if ! gpu_info=$(nvidia-smi --query-gpu=memory.total,driver_version,compute_mode --format=csv,noheader 2>/dev/null); then
		echo "WARNING: NVIDIA GPU not found, using default values"
		echo "memory=8Gi driver_version=535 compute_mode=Default"
		return
	fi
	echo "$gpu_info"
}

# Функция определения параметров безопасности
discover_security_config() {
	local user_id=$(id -u)
	local user_name=$(id -un)
	echo "user_id=$user_id user_name=$user_name"
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

# Экспорт всех обнаруженных параметров
export_discovered_values() {
	local repo_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
	local k8s_version=$(discover_kubernetes_version)
	local gpu_config=$(discover_gpu_config)
	local security_config=$(discover_security_config)
	local gpu_mounts=($(discover_gpu_mounts))
	local helm_charts=$(discover_helm_charts "$repo_root")
	read -r http_port https_port <<< "$(discover_available_ports)"
	
	cat << EOF
# Auto-discovered configuration $(date)
export KUBERNETES_VERSION="${k8s_version}"
export GPU_MEMORY=$(echo "$gpu_config" | cut -d',' -f1 | tr -d ' ')
export GPU_DRIVER_VERSION=$(echo "$gpu_config" | cut -d',' -f2 | tr -d ' ')
export GPU_COMPUTE_MODE=$(echo "$gpu_config" | cut -d',' -f3 | tr -d ' ')
export SECURITY_USER_ID=$(echo "$security_config" | cut -d' ' -f1 | cut -d'=' -f2)
export SECURITY_USER_NAME=$(echo "$security_config" | cut -d' ' -f2 | cut -d'=' -f2)
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