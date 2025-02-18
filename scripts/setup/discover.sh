#!/bin/bash

# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# Script for auto-discovering system configuration

# Функция определения версии Kubernetes
discover_kubernetes_version() {
	local latest_version
	latest_version=$(curl -s https://api.github.com/repos/kubernetes/kubernetes/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
	echo "${latest_version#v}"
}

# Функция определения CUDA версии
discover_cuda_version() {
	if command -v nvidia-smi &> /dev/null; then
		nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n1
	else
		echo "12.8" # Fallback version
	fi
}

# Функция определения NVIDIA драйвера
discover_nvidia_driver() {
	if command -v nvidia-smi &> /dev/null; then
		nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n1
	else
		echo "535.104.05" # Fallback version
	fi
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

# Экспорт обнаруженных значений
export_discovered_values() {
	local k8s_version=$(discover_kubernetes_version)
	local cuda_version=$(discover_cuda_version)
	local nvidia_driver=$(discover_nvidia_driver)
	local gpu_mounts=($(discover_gpu_mounts))
	read -r http_port https_port <<< "$(discover_available_ports)"
	
	cat << EOF
# Auto-discovered configuration $(date)
export KUBERNETES_VERSION="${k8s_version}"
export CUDA_VERSION="${cuda_version}"
export NVIDIA_DRIVER_VERSION="${nvidia_driver}"
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

# Если скрипт запущен напрямую, выводим конфигурацию
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	export_discovered_values
fi