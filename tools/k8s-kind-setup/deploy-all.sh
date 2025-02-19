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

# Проверка наличия необходимых файлов конфигурации
required_files=(
	"${SCRIPT_DIR}/env/src/env.sh"
	"${SCRIPT_DIR}/ascii-banners/src/ascii_banners.sh"
	"${SCRIPT_DIR}/setup-wsl/src/setup-wsl.sh"
	"${SCRIPT_DIR}/setup-bins/src/setup-bins.sh"
	"${SCRIPT_DIR}/setup-kind/src/setup-kind.sh"
	"${SCRIPT_DIR}/setup-ingress/src/setup-ingress.sh"
	"${SCRIPT_DIR}/setup-cert-manager/src/setup-cert-manager.sh"
	"${SCRIPT_DIR}/setup-dns/src/setup-dns.sh"
	"${SCRIPT_DIR}/dashboard-token/src/dashboard-token.sh"
	"${SCRIPT_DIR}/charts/src/charts.sh"
	"${REPO_ROOT}/tools/connectivity-check/check-services.sh"
)

# Проверка наличия всех необходимых файлов
for file in "${required_files[@]}"; do
	if [[ ! -f "$file" && ! -x "$file" ]]; then
		echo -e "${RED}Ошибка: Файл $file не найден или не является исполняемым${NC}"
		exit 1
	fi
done

# Загрузка общих переменных и баннеров
source "${SCRIPT_DIR}/env/src/env.sh"
source "${SCRIPT_DIR}/ascii-banners/src/ascii_banners.sh"

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
	local namespace=${3:-""}
	
	echo -e "\n${CYAN}[$component] Установка $description...${NC}"
	if [[ -x "${SCRIPT_DIR}/$component" ]]; then
		if [[ -n "$namespace" ]]; then
			"${SCRIPT_DIR}/$component" --namespace "$namespace"
		else
			"${SCRIPT_DIR}/$component"
		fi
		check_error "Ошибка при установке $description"
		echo -e "${GREEN}[$component] Установка $description завершена${NC}"
	else
		echo -e "${RED}Ошибка: Компонент $component не найден или не является исполняемым${NC}"
		exit 1
	fi
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
echo -e "\n${YELLOW}Начинаем развертывание компонентов...${NC}"

# Подготовка окружения
deploy_component "setup-wsl/src/setup-wsl.sh" "WSL окружения"
deploy_component "setup-bins/src/setup-bins.sh" "бинарных компонентов"
deploy_component "setup-kind/src/setup-kind.sh" "кластера Kind"

# Настройка кластера
deploy_component "setup-ingress/src/setup-ingress.sh" "Ingress Controller" "$NAMESPACE_INGRESS"
deploy_component "setup-cert-manager/src/setup-cert-manager.sh" "Cert Manager" "$NAMESPACE_CERT_MANAGER"
deploy_component "setup-dns/src/setup-dns.sh" "DNS" "$NAMESPACE_DNS"

# Установка Kubernetes Dashboard
echo -e "\n${CYAN}Установка Kubernetes Dashboard...${NC}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
check_error "Ошибка при установке Kubernetes Dashboard"

# Создание ServiceAccount и ClusterRoleBinding для Dashboard
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
	name: admin-user
	namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
	name: admin-user
roleRef:
	apiGroup: rbac.authorization.k8s.io
	kind: ClusterRole
	name: cluster-admin
subjects:
- kind: ServiceAccount
	name: admin-user
	namespace: kubernetes-dashboard
EOF
check_error "Ошибка при создании ServiceAccount для Dashboard"

# Установка всех чартов
echo -e "\n${CYAN}Установка Helm чартов...${NC}"
"${SCRIPT_DIR}/charts/src/charts.sh" install all
check_error "Ошибка при установке Helm чартов"

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

# Получение токена для Kubernetes Dashboard
echo -e "\n${CYAN}Получение токена для Kubernetes Dashboard...${NC}"
"${SCRIPT_DIR}/dashboard-token/src/dashboard-token.sh"