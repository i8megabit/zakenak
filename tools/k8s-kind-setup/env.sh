#!/bin/bash

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

# Пути к чартам
export CHART_PATH_OLLAMA="./helm-charts/ollama"
export CHART_PATH_WEBUI="./helm-charts/open-webui"

# DNS настройки
export DOMAIN_SUFFIX="prod.local"
export OLLAMA_HOST="ollama.$DOMAIN_SUFFIX"
export WEBUI_HOST="webui.$DOMAIN_SUFFIX"

# Настройки GPU
export NVIDIA_DRIVER_VERSION="535"
export CUDA_VERSION="12.8"
export NVIDIA_VISIBLE_DEVICES="all"
export NVIDIA_DRIVER_CAPABILITIES="compute,utility"

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