#!/usr/bin/bash
#  _____ _   ___     __ 
# | ____| \ | \ \   / / 
# |  _| |  \| |\ \ / /  
# | |___| |\  | \ V /   
# |_____|_| \_|  \_/    
#              by @eberil
#
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# Environment Configuration
# Version: 1.0.0
#
# HUJAK-HUJAK PRODUCTION PRESENTS...
# "Because environment variables should be fun"

# Определение базовой директории проекта
export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export TOOLS_DIR="${BASE_DIR}/tools/k8s-kind-setup"

# Экспорт путей к скриптам (динамические пути)
export SCRIPTS_ENV_PATH="${TOOLS_DIR}/env/src/env.sh"
export SCRIPTS_ASCII_BANNERS_PATH="${TOOLS_DIR}/ascii-banners/src/ascii_banners.sh"
export SCRIPTS_SETUP_WSL_PATH="${TOOLS_DIR}/setup-wsl/src/setup-wsl.sh"
export SCRIPTS_SETUP_BINS_PATH="${TOOLS_DIR}/setup-bins/src/setup-bins.sh"
export SCRIPTS_SETUP_KIND_PATH="${TOOLS_DIR}/setup-kind/src/setup-kind.sh"
export SCRIPTS_SETUP_INGRESS_PATH="${TOOLS_DIR}/setup-ingress/src/setup-ingress.sh"
export SCRIPTS_SETUP_CERT_MANAGER_PATH="${TOOLS_DIR}/setup-cert-manager/src/setup-cert-manager.sh"
export SCRIPTS_SETUP_DNS_PATH="${TOOLS_DIR}/setup-dns/src/setup-dns.sh"
export SCRIPTS_DASHBOARD_TOKEN_PATH="${TOOLS_DIR}/dashboard-token/src/dashboard-token.sh"
export SCRIPTS_CHARTS_PATH="${TOOLS_DIR}/charts/src/charts.sh"
export SCRIPTS_CONNECTIVITY_CHECK_PATH="${TOOLS_DIR}/connectivity-check/src/check-services.sh"


# Цветовые коды для вывода
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# Переменные окружения для кластера
export CLUSTER_NAME="kind"
export NAMESPACE_PROD="prod"
export NAMESPACE_INGRESS="ingress-nginx"
export NAMESPACE_CERT_MANAGER="cert-manager"

# Переменные для хостов сервисов
export OLLAMA_HOST="ollama.prod.local"
export WEBUI_HOST="webui.prod.local"

# Функция проверки ошибок
check_error() {
	if [ $? -ne 0 ]; then
		echo -e "${RED}$1${NC}"
		exit 1
	fi
}

# Функция ожидания готовности подов с повторными попытками
wait_for_pods() {
	local namespace=$1
	local selector=$2
	local timeout=${3:-600}  # Увеличенный таймаут по умолчанию до 600 секунд
	local max_attempts=${4:-3}  # Количество попыток по умолчанию
	local attempt=1

	while [ $attempt -le $max_attempts ]; do
		echo -e "${CYAN}Попытка $attempt из $max_attempts: Ожидание готовности подов в namespace $namespace...${NC}"
		
		if kubectl wait --for=condition=Ready pods -l $selector -n $namespace --timeout=${timeout}s; then
			echo -e "${GREEN}Поды успешно запущены!${NC}"
			return 0
		fi

		echo -e "${YELLOW}Попытка $attempt не удалась. Ожидание 30 секунд перед следующей попыткой...${NC}"
		sleep 30
		attempt=$((attempt + 1))
	done

	echo -e "${RED}Превышено количество попыток ожидания готовности подов${NC}"
	return 1
}

# Функция ожидания готовности CRDs
wait_for_crds() {
	local timeout=60
	for crd in "$@"; do
		echo -e "${CYAN}Ожидание готовности CRD $crd...${NC}"
		kubectl wait --for=condition=established crd/$crd --timeout=${timeout}s
		check_error "Превышено время ожидания готовности CRD $crd"
	done
}

# Функция проверки наличия GPU
check_gpu_available() {
	if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
		return 0
	else
		return 1
	fi
}

# Если скрипт запущен напрямую, выводим информацию о переменных
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	echo -e "${CYAN}Текущие настройки окружения:${NC}"
	echo -e "${YELLOW}Кластер:${NC} $CLUSTER_NAME"
	echo -e "${YELLOW}Namespace Production:${NC} $NAMESPACE_PROD"
	echo -e "${YELLOW}Namespace Ingress:${NC} $NAMESPACE_INGRESS"
	echo -e "${YELLOW}Namespace Cert Manager:${NC} $NAMESPACE_CERT_MANAGER"
	echo -e "\n${YELLOW}Хосты сервисов:${NC}"
	echo -e "Ollama API: https://$OLLAMA_HOST"
	echo -e "Open WebUI: https://$WEBUI_HOST"

	if check_gpu_available; then
		echo -e "\n${GREEN}GPU обнаружен${NC}"
	else
		echo -e "\n${YELLOW}GPU не обнаружен${NC}"
	fi
fi