#!/usr/bin/bash
#   ____ _____ ____  _____
#  / ___|_   _|  _ \|_   _|
# | |     | | | |_) | | |
# | |___  | | |  _ <  | |
#  \____| |_| |_| \_\ |_|
#                by @eberil
#
# Copyright (c)  2025 Mikhail Eberil
# This code is free! Share it, spread peace and technology!
# "Because certificates should be automated!"

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Загрузка общих переменных и баннеров
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/ascii_banners.sh"

# Отображение баннера при старте
cert_banner
echo ""

echo -e "${CYAN}Установка cert-manager...${NC}"

# Создание необходимых namespace

kubectl create namespace $NAMESPACE_PROD --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $NAMESPACE_CERT_MANAGER --dry-run=client -o yaml | kubectl apply -f -

# Установка cert-manager с CRDs
helm upgrade --install $RELEASE_CERT_MANAGER jetstack/cert-manager \
    --namespace $NAMESPACE_CERT_MANAGER \
    --set installCRDs=true \
    --wait
check_error "Не удалось установить cert-manager"

# Ожидание готовности CRDs
wait_for_crds "certificates.cert-manager.io" "clusterissuers.cert-manager.io" "issuers.cert-manager.io"

# Ожидание готовности подов cert-manager
wait_for_pods $NAMESPACE_CERT_MANAGER "app.kubernetes.io/instance=cert-manager"

echo -e "${GREEN}Установка cert-manager успешно завершена!${NC}"