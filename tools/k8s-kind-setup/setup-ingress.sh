#!/usr/bin/bash
#  ___                              
# |_ _|_ __   __ _ _ __ ___  ___ ___
#  | || '_ \ / _` | '__/ _ \/ __/ __|
#  | || | | | (_| | | |  __/\__ \__ \
# |___|_| |_|\__, |_|  \___||___/___/
#            |___/         by @eberil
#
# Copyright (c) 2024 Mikhail Eberil
# This code is free! Share it, spread peace and technology!
# "Because Ingress should just work!"

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Загрузка общих переменных и баннеров
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/ascii_banners.sh"

# Отображение баннера при старте
ingress_banner
echo ""

echo -e "${CYAN}Установка Ingress Controller...${NC}"

# Добавление репозитория ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
check_error "Не удалось добавить репозиторий ingress-nginx"

# Установка Ingress Controller
helm upgrade --install $RELEASE_INGRESS ingress-nginx/ingress-nginx \
	--namespace $NAMESPACE_INGRESS \
	--create-namespace \
	--set controller.service.type=NodePort \
	--set controller.hostPort.enabled=true \
	--set controller.service.nodePorts.http=80 \
	--set controller.service.nodePorts.https=443 \
	--wait
check_error "Не удалось установить Ingress Controller"

# Ожидание готовности подов
wait_for_pods $NAMESPACE_INGRESS "app.kubernetes.io/component=controller"

echo -e "\n"
success_banner
echo -e "\n${GREEN}Установка Ingress Controller успешно завершена!${NC}"