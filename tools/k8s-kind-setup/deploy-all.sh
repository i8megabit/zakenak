#!/usr/bin/bash
#  ____             _             
# |  _ \  ___ _ __ | | ___  _   _ 
# | | | |/ _ \ '_ \| |/ _ \| | | |
# | |_| |  __/ |_) | | (_) | |_| |
# |____/ \___| .__/|_|\___/ \__, |
#            |_|            |___/ 
#                         by @eberil
#
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# This code is free! Share it, spread peace and technology!
# "Time to ship some containers!"

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Загрузка общих переменных и баннеров
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/ascii_banners.sh"

# Отображение баннера при старте
production_banner
echo ""

# Функция для проверки наличия необходимых утилит
check_prerequisites() {
	local required_tools=("curl" "wget" "gpg")
	for tool in "${required_tools[@]}"; do
		if ! command -v "$tool" &> /dev/null; then
			echo -e "${RED}Ошибка: $tool не установлен${NC}"
			exit 1
		fi
	done
}

# Функция для запуска компонента с единым форматом вывода
deploy_component() {
	local component=$1
	local description=$2
	
	echo -e "\n${CYAN}[$component] Установка $description...${NC}"
	"${SCRIPT_DIR}/$component"
	check_error "Ошибка при установке $description"
	echo -e "${GREEN}[$component] Установка $description завершена${NC}"
}

# Функция для вывода статуса компонентов
show_deployment_status() {
	echo -e "\n${CYAN}Статус компонентов в пространстве $NAMESPACE_PROD:${NC}"
	kubectl get pods -n $NAMESPACE_PROD -o wide
	
	echo -e "\n${CYAN}Статус Ingress Controller:${NC}"
	kubectl get pods -n $NAMESPACE_INGRESS -o wide
	
	echo -e "\n${CYAN}Статус Ingress ресурсов:${NC}"
	kubectl get ingress -n $NAMESPACE_PROD -o wide
}

# Проверка prerequisites
echo -e "${YELLOW}Проверка необходимых компонентов...${NC}"
check_prerequisites

echo -e "\n"
deploy_banner
echo -e "\n${YELLOW}Начинаем развертывание компонентов...${NC}"

# Последовательный запуск всех компонентов
deploy_component "setup-wsl/src/setup-wsl.sh" "WSL окружения"
deploy_component "setup-bins/src/setup-bins.sh" "бинарных компонентов"
deploy_component "setup-kind/src/setup-kind.sh" "кластера Kind"
deploy_component "setup-ingress.sh" "Ingress Controller"
deploy_component "setup-cert-manager.sh" "Cert Manager"
deploy_component "setup-dns.sh" "DNS"

# Установка приложений через charts

echo -e "\n${CYAN}Установка приложений...${NC}"
"${SCRIPT_DIR}/charts" install ollama
check_error "Ошибка при установке Ollama"

"${SCRIPT_DIR}/charts" install open-webui
check_error "Ошибка при установке Open WebUI"

# Проверка работоспособности сервисов
echo -e "\n${CYAN}Проверка работоспособности сервисов...${NC}"
"${REPO_ROOT}/tools/connectivity-check/check-services.sh"
check_error "Ошибка при проверке сервисов"

# Вывод статуса развертывания
show_deployment_status

echo -e "\n"
success_banner
echo -e "\n${GREEN}Развертывание успешно завершено!${NC}"
echo -e "${YELLOW}Для проверки доступности сервисов:${NC}"
echo -e "1. Ollama API: https://$OLLAMA_HOST"
echo -e "2. Open WebUI: https://$WEBUI_HOST"