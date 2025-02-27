#!/usr/bin/bash
#  _    _ _    _ _          _  __      _    _ _    _ _          _  __ 
# | |  | | |  | | |   /\   | |/ /     | |  | | |  | | |   /\   | |/ / 
# | |__| | |  | | |  /  \  | ' /      | |__| | |  | | |  /  \  | ' / 
# |  __  | |  | | | / /\ \ |  <       |  __  | |  | | | / /\ \ |  <  
# | |  | | |__| | |/ ____ \| . \      | |  | | |__| | |/ ____ \| . \ 
# |_|  |_|\____/|_/_/    \_\_|\_\     |_|  |_|\____/|_/_/    \_\_|\_\
#                                                           by @eberil
#
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# This code is free! Share it, spread peace and technology!

# Функция для вывода справки по использованию
show_banner_usage() {
	echo "Usage: $0 [banner_type] [message]"
	echo "Available banner types:"
	echo "  devops     - Show DevOps banner"
	echo "  ingress    - Show Ingress banner"
	echo "  dns        - Show DNS banner"
	echo "  cert       - Show Cert Manager banner"
	echo "  local-ca   - Show Local CA banner"
	echo "  dashboard  - Show Dashboard banner"
	echo "  nginx      - Show NGINX Ingress banner"
	echo "  coredns    - Show CoreDNS banner"
	echo "  prometheus - Show Prometheus banner"
	echo "  grafana    - Show Grafana banner"
	echo "  k8s        - Show Kubernetes banner"
	echo "  deploy     - Show Deploy banner"
	echo "  charts     - Show Charts banner"
	echo "  ollama     - Show Ollama banner"
	echo "  open-webui - Show Open WebUI banner"
	echo "  sidecar-injector - Show Sidecar Injector banner"
	echo "  error      - Show Error message with optional custom text"
	echo "  success    - Show Success message with optional custom text"
	echo "  warning    - Show Warning message with optional custom text"
}

# Основная логика обработки аргументов
main() {
	if [ $# -eq 0 ]; then
		show_banner_usage
		exit 1
	fi

	case "$1" in
		"devops")
			devops_banner
			;;
		"ingress")
			ingress_banner
			;;
		"dns")
			dns_banner
			;;
		"cert")
			cert_manager_banner
			;;
		"local-ca")
			local_ca_banner
			;;
		"dashboard")
			dashboard_banner
			;;
		"nginx")
			nginx_ingress_banner
			;;
		"coredns")
			coredns_banner
			;;
		"prometheus")
			prometheus_banner
			;;
		"grafana")
			grafana_banner
			;;
		"k8s")
			k8s_banner
			;;
		"deploy")
			show_deploy_banner
			;;
		"charts")
			charts_banner
			;;
		"error")
			error_banner "$2"
			;;
		"success")
			success_banner "$2"
			;;
		"warning")
			warning_banner "$2"
			;;
		*)
			echo -e "${RED}Error: Unknown banner type '$1'${NC}"
			show_banner_usage
			exit 1
			;;
	esac
}

# Определение цветов
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# DevOps Banner
devops_banner() {
	echo -e "${BLUE}"
	cat << "EOF"
  ██████╗ ███████╗██╗   ██╗ ██████╗ ██████╗ ███████╗
  ██╔══██╗██╔════╝██║   ██║██╔═══██╗██╔══██╗██╔════╝
  ██║  ██║█████╗  ██║   ██║██║   ██║██████╔╝███████╗
  ██║  ██║██╔══╝  ╚██╗ ██╔╝██║   ██║██╔═══╝ ╚════██║
  ██████╔╝███████╗ ╚████╔╝ ╚██████╔╝██║     ███████║
  ╚═════╝ ╚══════╝  ╚═══╝   ╚═════╝ ╚═╝     ╚══════╝
EOF
	echo -e "${NC}"
	echo "Copyright (c) 2023-2025 Mikhail Eberil (@eberil)"
	echo "This code is free! Share it, spread peace and technology!"
	echo '"Because DevOps is about sharing and caring"'
}

# Функция проверки поддержки цвета терминалом
check_color_support() {
	if ! test -t 1; then
		# Терминал не поддерживает цвет или это не терминал
		RED=''
		GREEN=''
		YELLOW=''
		BLUE=''
		CYAN=''
		NC=''
	fi
}

# Инициализация
check_color_support

# Запуск основной логики только если не установлен флаг пропуска и скрипт запущен напрямую
if [ -z "$SKIP_BANNER_MAIN" ] && [ "${BASH_SOURCE[0]}" = "$0" ]; then
	main "$@"
fi

# Ingress Banner
ingress_banner() {
	echo -e "${BLUE}"
	cat << "EOF"
  ██╗███╗   ██╗ ██████╗ ██████╗ ███████╗███████╗███████╗
  ██║████╗  ██║██╔════╝ ██╔══██╗██╔════╝██╔════╝██╔════╝
  ██║██╔██╗ ██║██║  ███╗██████╔╝█████╗  ███████╗███████╗
  ██║██║╚██╗██║██║   ██║██╔══██╗██╔══╝  ╚════██║╚════██║
  ██║██║ ╚████║╚██████╔╝██║  ██║███████╗███████║███████║
  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
EOF
	echo -e "${NC}"
	echo "Route Your Traffic with Style"
}

# Nginx Ingress Banner
nginx_ingress_banner() {
	echo -e "${BLUE}"
	cat << "EOF"
  ███╗   ██╗ ██████╗ ██╗███╗   ██╗██╗  ██╗
  ████╗  ██║██╔════╝ ██║████╗  ██║╚██╗██╔╝
  ██╔██╗ ██║██║  ███╗██║██╔██╗ ██║ ╚███╔╝ 
  ██║╚██╗██║██║   ██║██║██║╚██╗██║ ██╔██╗ 
  ██║ ╚████║╚██████╔╝██║██║ ╚████║██╔╝ ██╗
  ╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝
EOF
	echo -e "${NC}"
	echo "Your Gateway to Kubernetes Services"
}

# CoreDNS Banner
coredns_banner() {
	echo -e "${BLUE}"
	cat << "EOF"
   ██████╗ ██████╗ ██████╗ ███████╗██████╗ ███╗   ██╗███████╗
  ██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔══██╗████╗  ██║██╔════╝
  ██║     ██║   ██║██████╔╝█████╗  ██║  ██║██╔██╗ ██║███████╗
  ██║     ██║   ██║██╔══██╗██╔══╝  ██║  ██║██║╚██╗██║╚════██║
  ╚██████╗╚██████╔╝██║  ██║███████╗██████╔╝██║ ╚████║███████║
   ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝  ╚═══╝╚══════╝
EOF
	echo -e "${NC}"
	echo "DNS for Your Kubernetes Cluster"
}

# Prometheus Banner
prometheus_banner() {
	echo -e "${BLUE}"
	cat << "EOF"
  ██████╗ ██████╗  ██████╗ ███╗   ███╗███████╗████████╗██╗  ██╗███████╗██╗   ██╗███████╗
  ██╔══██╗██╔══██╗██╔═══██╗████╗ ████║██╔════╝╚══██╔══╝██║  ██║██╔════╝██║   ██║██╔════╝
  ██████╔╝██████╔╝██║   ██║██╔████╔██║█████╗     ██║   ███████║█████╗  ██║   ██║███████╗
  ██╔═══╝ ██╔══██╗██║   ██║██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██╔══╝  ██║   ██║╚════██║
  ██║     ██║  ██║╚██████╔╝██║ ╚═╝ ██║███████╗   ██║   ██║  ██║███████╗╚██████╔╝███████║
  ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚══════╝
EOF
	echo -e "${NC}"
	echo "Time Series Monitoring for Your Infrastructure"
}

# Grafana Banner
grafana_banner() {
	echo -e "${BLUE}"
	cat << "EOF"
   ██████╗ ██████╗  █████╗ ███████╗ █████╗ ███╗   ██╗ █████╗ 
  ██╔════╝ ██╔══██╗██╔══██╗██╔════╝██╔══██╗████╗  ██║██╔══██╗
  ██║  ███╗██████╔╝███████║█████╗  ███████║██╔██╗ ██║███████║
  ██║   ██║██╔══██╗██╔══██║██╔══╝  ██╔══██║██║╚██╗██║██╔══██║
  ╚██████╔╝██║  ██║██║  ██║██║     ██║  ██║██║ ╚████║██║  ██║
   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝
EOF
	echo -e "${NC}"
	echo "Visualize Your Metrics"
}

# Запуск основной логики только если не установлен флаг пропуска и скрипт запущен напрямую
if [ -z "$SKIP_BANNER_MAIN" ] && [ "${BASH_SOURCE[0]}" = "$0" ]; then
	main "$@"
fi

# DNS Banner
dns_banner() {
	echo -e "${BLUE}"
	cat << "EOF"
  ██████╗ ███╗   ██╗███████╗
  ██╔══██╗████╗  ██║██╔════╝
  ██║  ██║██╔██╗ ██║███████╗
  ██║  ██║██║╚██╗██║╚════██║
  ██████╔╝██║ ╚████║███████║
  ╚═════╝ ╚═╝  ╚═══╝╚══════╝
EOF
	echo -e "${NC}"
}

# Cert Manager Banner
cert_manager_banner() {
	echo -e "${BLUE}"
	cat << "EOF"
   ██████╗███████╗██████╗ ████████╗    ███╗   ███╗ ██████╗ ██████╗ 
  ██╔════╝██╔════╝██╔══██╗╚══██╔══╝    ████╗ ████║██╔════╝ ██╔══██╗
  ██║     █████╗  ██████╔╝   ██║       ██╔████╔██║██║  ███╗██████╔╝
  ██║     ██╔══╝  ██╔══██╗   ██║       ██║╚██╔╝██║██║   ██║██╔══██╗
  ╚██████╗███████╗██║  ██║   ██║       ██║ ╚═╝ ██║╚██████╔╝██║  ██║
   ╚═════╝╚══════╝╚═╝  ╚═╝   ╚═╝       ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝
EOF
	echo -e "${NC}"
	echo "Secure your cluster with cert-manager"
}

# Local CA Banner
local_ca_banner() {
	echo -e "${BLUE}"
	cat << "EOF"
  ██╗      ██████╗  ██████╗ █████╗ ██╗          ██████╗█████╗ 
  ██║     ██╔═══██╗██╔════╝██╔══██╗██║         ██╔════╝██╔══██╗
  ██║     ██║   ██║██║     ███████║██║         ██║     ███████║
  ██║     ██║   ██║██║     ██╔══██║██║         ██║     ██╔══██║
  ███████╗╚██████╔╝╚██████╗██║  ██║███████╗    ╚██████╗██║  ██║
  ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝     ╚═════╝╚═╝  ╚═╝
EOF
	echo -e "${NC}"
	echo "Your local Certificate Authority"
}

# Dashboard Banner
dashboard_banner() {
	echo -e "${BLUE}"
	cat << "EOF"
  ██████╗  █████╗ ███████╗██╗  ██╗██████╗  ██████╗  █████╗ ██████╗ ██████╗ 
  ██╔══██╗██╔══██╗██╔════╝██║  ██║██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██╔══██╗
  ██║  ██║███████║███████╗███████║██████╔╝██║   ██║███████║██████╔╝██║  ██║
  ██║  ██║██╔══██║╚════██║██╔══██║██╔══██╗██║   ██║██╔══██║██╔══██╗██║  ██║
  ██████╔╝██║  ██║███████║██║  ██║██████╔╝╚██████╔╝██║  ██║██║  ██║██████╔╝
  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ 
EOF
	echo -e "${NC}"
}

# K8s Banner
k8s_banner() {
	echo -e "${BLUE}"
	cat << "EOF"
  ██╗  ██╗ █████╗ ███████╗
  ██║ ██╔╝██╔══██╗██╔════╝
  █████╔╝ ╚█████╔╝███████╗
  ██╔═██╗ ██╔══██╗╚════██║
  ██║  ██╗╚█████╔╝███████║
  ╚═╝  ╚═╝ ╚════╝ ╚══════╝
EOF
	echo -e "${NC}"
}

# Deploy Banner
show_deploy_banner() {
	echo -e "${BLUE}"
	cat << "EOF"
  ██████╗ ███████╗██████╗ ██╗      ██████╗ ██╗   ██╗
  ██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗╚██╗ ██╔╝
  ██║  ██║█████╗  ██████╔╝██║     ██║   ██║ ╚████╔╝ 
  ██║  ██║██╔══╝  ██╔═══╝ ██║     ██║   ██║  ╚██╔╝  
  ██████╔╝███████╗██║     ███████╗╚██████╔╝   ██║   
  ╚═════╝ ╚══════╝╚═╝     ╚══════╝ ╚═════╝    ╚═╝   
EOF
	echo -e "${NC}"
}


# Charts Banner
charts_banner() {
	echo -e "${BLUE}"
	cat << "EOF"
   ██████╗██╗  ██╗ █████╗ ██████╗ ████████╗███████╗
  ██╔════╝██║  ██║██╔══██╗██╔══██╗╚══██╔══╝██╔════╝
  ██║     ███████║███████║██████╔╝   ██║   ███████╗
  ██║     ██╔══██║██╔══██║██╔══██╗   ██║   ╚════██║
  ╚██████╗██║  ██║██║  ██║██║  ██║   ██║   ███████║
   ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝
EOF
	echo -e "${NC}"
	echo "Copyright (c) 2023-2025 Mikhail Eberil (@eberil)"
	echo '"Because managing charts shouldn'\''t be a pain"'
}


# Error Banner - replaced with colored message
error_banner() {
    local message="${1:-"Произошла ошибка"}"
    echo -e "\n${RED}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${RED}│ ОШИБКА: ${message} ${NC}"
    echo -e "${RED}└──────────────────────────────────────────────────────────────┘${NC}\n"
}

# Success Banner - replaced with colored message
success_banner() {
    local message="${1:-"Операция выполнена успешно"}"
    echo -e "\n${GREEN}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│ УСПЕХ: ${message} ${NC}"
    echo -e "${GREEN}└──────────────────────────────────────────────────────────────┘${NC}\n"
}

# Warning Banner - new function for warnings
warning_banner() {
    local message="${1:-"Предупреждение"}"
    echo -e "\n${YELLOW}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│ ПРЕДУПРЕЖДЕНИЕ: ${message} ${NC}"
    echo -e "${YELLOW}└──────────────────────────────────────────────────────────────┘${NC}\n"
}