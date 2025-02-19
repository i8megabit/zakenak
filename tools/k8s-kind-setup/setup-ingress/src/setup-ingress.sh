#!/usr/bin/bash

# Определение пути к директории скрипта и корню репозитория
export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export TOOLS_DIR="${BASE_DIR}/tools/k8s-kind-setup"
export SCRIPTS_ENV_PATH="${TOOLS_DIR}/env/src/env.sh"

# Загрузка общих переменных и баннеров
source "${SCRIPTS_ENV_PATH}"
source "${SCRIPTS_ASCII_BANNERS_PATH}"

# Отображение баннера
ingress_banner

echo -e "${CYAN}Установка Ingress NGINX Controller...${NC}"

# Добавление репозитория ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Установка ingress-nginx с использованием конфигурационного файла
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
	--namespace "${NAMESPACE_INGRESS}" \
	--create-namespace \
	--values "$(dirname "${BASH_SOURCE[0]}")/ingress-config.yaml"

check_error "Ошибка установки Ingress NGINX Controller"

# Ожидание готовности ingress-controller
echo -e "${CYAN}Ожидание готовности Ingress Controller...${NC}"
if ! wait_for_pods "${NAMESPACE_INGRESS}" "app.kubernetes.io/component=controller" 900 5; then
	echo -e "${RED}Ошибка при ожидании готовности Ingress Controller${NC}"
	exit 1
fi


echo -e "${GREEN}Ingress NGINX Controller успешно установлен!${NC}"
