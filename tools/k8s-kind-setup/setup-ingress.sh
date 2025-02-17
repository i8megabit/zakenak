#!/usr/bin/bash
#  ___                              
# |_ _|_ __   __ _ _ __ ___  ___ ___
#  | || '_ \ / _` | '__/ _ \/ __/ __|
#  | || | | | (_| | | |  __/\__ \__ \
# |___|_| |_|\__, |_|  \___||___/___/
#            |___/
#
# Copyright (c)  2025 Mikhail Eberil
# This code is free! Share it, spread peace and technology!
# "Because Ingress should just work!"

set -e

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Загрузка общих переменных и баннеров
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/ascii_banners.sh"

echo -e "${CYAN}Установка Ingress Controller...${NC}"

# Добавление репозитория ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
check_error "Не удалось добавить репозиторий ingress-nginx"

# Установка Ingress Controller с правильной конфигурацией для Kind
helm upgrade --install $RELEASE_INGRESS ingress-nginx/ingress-nginx \
	--namespace $NAMESPACE_INGRESS \
	--create-namespace \
	--set controller.service.type=NodePort \
	--set controller.hostPort.enabled=true \
	--set controller.service.ports.http=80 \
	--set controller.service.ports.https=443 \
	--set controller.service.nodePorts.http=30080 \
	--set controller.service.nodePorts.https=30443 \
	--set controller.watchIngressWithoutClass=true \
	--wait
check_error "Не удалось установить Ingress Controller"

# Ожидание готовности подов
kubectl wait --namespace $NAMESPACE_INGRESS \
	--for=condition=ready pod \
	--selector=app.kubernetes.io/component=controller \
	--timeout=90s
check_error "Не удалось дождаться готовности Ingress Controller"

echo -e "\n"
success_banner
echo -e "\n${GREEN}Установка Ingress Controller успешно завершена!${NC}"