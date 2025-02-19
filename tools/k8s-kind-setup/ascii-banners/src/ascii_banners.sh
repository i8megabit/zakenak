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
	echo "Usage: $0 [banner_type]"
	echo "Available banner types:"
	echo "  devops     - Show DevOps banner"
	echo "  ingress    - Show Ingress banner"
	echo "  dns        - Show DNS banner"
	echo "  cert       - Show Cert Manager banner"
	echo "  dashboard  - Show Dashboard banner"
	echo "  k8s        - Show Kubernetes banner"
	echo "  deploy     - Show Deploy banner"
	echo "  charts     - Show Charts banner"
	echo "  error      - Show Error banner"
	echo "  success    - Show Success banner"
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
		"dashboard")
			dashboard_banner
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
			error_banner
			;;
		"success")
			success_banner
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
}

# Запуск основной логики только если не установлен флаг пропуска
if [ -z "$SKIP_BANNER_MAIN" ]; then
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
   ██████╗███████╗██████╗ ████████╗███████╗
  ██╔════╝██╔════╝██╔══██╗╚══██╔══╝██╔════╝
  ██║     █████╗  ██████╔╝   ██║   ███████╗
  ██║     ██╔══╝  ██╔══██╗   ██║   ╚════██║
  ╚██████╗███████╗██║  ██║   ██║   ███████║
   ╚═════╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝
EOF
	echo -e "${NC}"
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


# Error Banner
error_banner() {
	echo -e "${RED}"
	cat << "EOF"
  ███████╗██████╗ ██████╗  ██████╗ ██████╗ 
  ██╔════╝██╔══██╗██╔══██╗██╔═══██╗██╔══██╗
  █████╗  ██████╔╝██████╔╝██║   ██║██████╔╝
  ██╔══╝  ██╔══██╗██╔══██╗██║   ██║██╔══██╗
  ███████╗██║  ██║██║  ██║╚██████╔╝██║  ██║
  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝
EOF
	echo -e "${NC}"
}

# Success Banner
success_banner() {
	echo -e "${GREEN}"
	cat << "EOF"
  ███████╗██╗   ██╗ ██████╗ ██████╗███████╗███████╗███████╗
  ██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝
  ███████╗██║   ██║██║     ██║     █████╗  ███████╗███████╗
  ╚════██║██║   ██║██║     ██║     ██╔══╝  ╚════██║╚════██║
  ███████║╚██████╔╝╚██████╗╚██████╗███████╗███████║███████║
  ╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝
EOF
	echo -e "${NC}"
}