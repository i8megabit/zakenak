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

# Экспорт путей к скриптам (статические пути)
export SCRIPTS_ENV_PATH="/home/eberil/zakenak-1/tools/k8s-kind-setup/env/src/env.sh"
export SCRIPTS_ASCII_BANNERS_PATH="/home/eberil/zakenak-1/tools/k8s-kind-setup/ascii-banners/src/ascii_banners.sh"
export SCRIPTS_SETUP_WSL_PATH="/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-wsl/src/setup-wsl.sh"
export SCRIPTS_SETUP_BINS_PATH="/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-bins/src/setup-bins.sh"
export SCRIPTS_SETUP_KIND_PATH="/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-kind/src/setup-kind.sh"
export SCRIPTS_SETUP_INGRESS_PATH="/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-ingress/src/setup-ingress.sh"
export SCRIPTS_SETUP_CERT_MANAGER_PATH="/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-cert-manager/src/setup-cert-manager.sh"
export SCRIPTS_SETUP_DNS_PATH="/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-dns/src/setup-dns.sh"
export SCRIPTS_DASHBOARD_TOKEN_PATH="/home/eberil/zakenak-1/tools/k8s-kind-setup/dashboard-token/src/dashboard-token.sh"
export SCRIPTS_CHARTS_PATH="/home/eberil/zakenak-1/tools/k8s-kind-setup/charts/src/charts.sh"
export SCRIPTS_CONNECTIVITY_CHECK_PATH="/home/eberil/zakenak-1/tools/k8s-kind-setup/connectivity-check/src/check-services.sh"


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

# Функция ожидания готовности подов
wait_for_pods() {
	local namespace=$1
	local selector=$2
	local timeout=300

	echo -e "${CYAN}Ожидание готовности подов в namespace $namespace...${NC}"
	kubectl wait --for=condition=Ready pods -l $selector -n $namespace --timeout=${timeout}s
	check_error "Превышено время ожидания готовности подов"
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
fi