#!/bin/bash

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Цвета для вывода
export YELLOW='\033[1;33m'
export CYAN='\033[0;36m'
export GREEN='\033[0;32m'
export RED='\033[0;31m'
export NC='\033[0m'

# Названия неймспейсов
export NAMESPACE_PROD="prod"
export NAMESPACE_INGRESS="ingress-nginx"
export NAMESPACE_CERT_MANAGER="cert-manager"

# Названия релизов
export RELEASE_OLLAMA="ollama"
export RELEASE_WEBUI="open-webui"
export RELEASE_INGRESS="ingress-nginx"
export RELEASE_CERT_MANAGER="cert-manager"

# Пути к чартам (относительно корня репозитория)
export CHART_PATH_OLLAMA="${REPO_ROOT}/helm-charts/ollama"
export CHART_PATH_WEBUI="${REPO_ROOT}/helm-charts/open-webui"

# DNS настройки
export DOMAIN_SUFFIX="prod.local"
export OLLAMA_HOST="ollama.$DOMAIN_SUFFIX"
export WEBUI_HOST="webui.$DOMAIN_SUFFIX"

# Настройки GPU для WSL2
export PATH="/usr/lib/wsl/lib:$PATH"
export LD_LIBRARY_PATH="/usr/lib/wsl/lib:$LD_LIBRARY_PATH"
export NVIDIA_DRIVER_VERSION="535"
export CUDA_VERSION="12.8"
export NVIDIA_VISIBLE_DEVICES="all"
export NVIDIA_DRIVER_CAPABILITIES="compute,utility,video"
export WSL_NVIDIA_SMI_PATH="/usr/lib/wsl/lib/nvidia-smi"
export NVIDIA_CONTAINER_RUNTIME="nvidia"
export NVIDIA_CONTAINER_CLI="nvidia-container-cli"
export NVIDIA_CONTAINER_RUNTIME_ARGS="--gpus all"

# Настройки сертификатов
export CA_ISSUER_NAME="local-ca-issuer"
export CA_CERT_NAME="local-ca"
export CA_SECRET_NAME="local-ca-key-pair"

# Функция проверки ошибок
check_error() {
	if [ $? -ne 0 ]; then
		echo -e "${RED}Ошибка: $1${NC}"
		exit 1
	fi
}

# Функция ожидания готовности подов
wait_for_pods() {
	namespace=$1
	label=$2
	echo -e "${CYAN}Ожидание готовности подов в namespace $namespace с меткой $label...${NC}"
	kubectl wait --for=condition=Ready pods -l $label -n $namespace --timeout=300s
	check_error "Поды не готовы в namespace $namespace"
}
