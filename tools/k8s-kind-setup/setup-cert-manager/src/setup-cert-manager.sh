#!/usr/bin/bash
#   ____ _____ ____ _____ 
#  / ___|  ___| __ )_   _|
# | |   | |_  |  _ \ | |  
# | |___|  _| | |_) || |  
#  \____|_|   |____/ |_|  
#                by @eberil
#
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# This code is free! Share it, spread peace and technology!
# "Because certificates should be automated!"

# Определение пути к директории скрипта и корню репозитория
export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export TOOLS_DIR="${BASE_DIR}/tools/k8s-kind-setup"
export SCRIPTS_ENV_PATH="${TOOLS_DIR}/env/src/env.sh"

# Загрузка общих переменных и баннеров
source "${SCRIPTS_ENV_PATH}"
source "${SCRIPTS_ASCII_BANNERS_PATH}"

# Определение имени релиза
RELEASE_CERT_MANAGER="cert-manager"

# Отображение баннера при старте
cert_manager_banner
echo ""

echo -e "${CYAN}Установка cert-manager...${NC}"

# Добавление репозитория cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
check_error "Не удалось добавить репозиторий cert-manager"

# Установка cert-manager с CRDs
helm upgrade --install $RELEASE_CERT_MANAGER jetstack/cert-manager \
	--namespace $NAMESPACE_CERT_MANAGER \
	--create-namespace \
	--set installCRDs=true \
	--wait
check_error "Не удалось установить cert-manager"

# Ожидание готовности CRDs
echo -e "${CYAN}Ожидание готовности CRDs...${NC}"
kubectl wait --for=condition=established --timeout=60s \
	crd/certificates.cert-manager.io \
	crd/clusterissuers.cert-manager.io \
	crd/issuers.cert-manager.io
check_error "Ошибка при ожидании готовности CRDs"

# Ожидание готовности подов
echo -e "${CYAN}Ожидание готовности подов cert-manager...${NC}"
kubectl wait --namespace $NAMESPACE_CERT_MANAGER \
	--for=condition=ready pod \
	--selector=app.kubernetes.io/instance=cert-manager \
	--timeout=90s
check_error "Не удалось дождаться готовности cert-manager"

# Создание ClusterIssuer для самоподписанных сертификатов
echo -e "${CYAN}Создание ClusterIssuer...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
EOF
check_error "Не удалось создать ClusterIssuer"

success_banner
echo -e "${GREEN}Установка cert-manager успешно завершена!${NC}"
