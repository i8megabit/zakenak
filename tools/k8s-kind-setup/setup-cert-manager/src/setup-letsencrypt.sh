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
# "Because certificates should be trusted!"

# Определение пути к директории скрипта и корню репозитория
export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export TOOLS_DIR="${BASE_DIR}/tools/k8s-kind-setup"
export SCRIPTS_ENV_PATH="${TOOLS_DIR}/env/src/env.sh"

# Загрузка общих переменных и баннеров
if [ -f "${SCRIPTS_ENV_PATH}" ]; then
    source "${SCRIPTS_ENV_PATH}"
else
    # Fallback colors if env.sh is not available
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
    
    # Fallback variables
    NAMESPACE_CERT_MANAGER="cert-manager"
    NAMESPACE_PROD="prod"
fi

# Отображение баннера при старте
echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}   Настройка Let's Encrypt с Cloudflare DNS  ${NC}"
echo -e "${CYAN}=====================================${NC}"
echo ""

# Проверка наличия kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Ошибка: kubectl не установлен${NC}"
    exit 1
fi

# Проверка доступности кластера
echo -e "${CYAN}Проверка доступности кластера...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Ошибка: Нет доступа к кластеру Kubernetes${NC}"
    exit 1
fi

# Проверка наличия переменной окружения CLOUDFLARE_API_TOKEN
if [ -z "${CLOUDFLARE_API_TOKEN}" ]; then
    echo -e "${YELLOW}Переменная окружения CLOUDFLARE_API_TOKEN не установлена${NC}"
    echo -e "${YELLOW}Для продолжения необходимо установить эту переменную${NC}"
    echo -e "${YELLOW}Пример: export CLOUDFLARE_API_TOKEN=\"ваш-api-токен-cloudflare\"${NC}"
    exit 1
fi

# Проверка наличия cert-manager
echo -e "${CYAN}Проверка наличия cert-manager...${NC}"
if ! kubectl get namespace "${NAMESPACE_CERT_MANAGER}" &> /dev/null; then
    echo -e "${YELLOW}Namespace ${NAMESPACE_CERT_MANAGER} не найден${NC}"
    echo -e "${YELLOW}Установка cert-manager...${NC}"
    
    # Установка cert-manager
    "${TOOLS_DIR}/charts/src/charts.sh" install cert-manager --values "${BASE_DIR}/helm-charts/cert-manager/values.prod.yaml"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка при установке cert-manager${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}cert-manager успешно установлен${NC}"
else
    echo -e "${GREEN}cert-manager уже установлен${NC}"
fi

# Создание секрета с API токеном Cloudflare
echo -e "${CYAN}Создание секрета с API токеном Cloudflare...${NC}"
kubectl create secret generic cloudflare-api-token-secret \
    --namespace="${NAMESPACE_PROD}" \
    --from-literal=api-token="${CLOUDFLARE_API_TOKEN}" \
    --dry-run=client -o yaml | kubectl apply -f -

if [ $? -ne 0 ]; then
    echo -e "${RED}Ошибка при создании секрета с API токеном Cloudflare${NC}"
    exit 1
fi

echo -e "${GREEN}Секрет с API токеном Cloudflare успешно создан${NC}"

# Проверка наличия ClusterIssuer
echo -e "${CYAN}Проверка наличия ClusterIssuer...${NC}"
if ! kubectl get clusterissuer letsencrypt-issuer &> /dev/null; then
    echo -e "${YELLOW}ClusterIssuer letsencrypt-issuer не найден${NC}"
    echo -e "${YELLOW}Обновление cert-manager...${NC}"
    
    # Обновление cert-manager с настройками для Let's Encrypt
    "${TOOLS_DIR}/charts/src/charts.sh" upgrade cert-manager --values "${BASE_DIR}/helm-charts/cert-manager/values.prod.yaml"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка при обновлении cert-manager${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}cert-manager успешно обновлен${NC}"
else
    echo -e "${GREEN}ClusterIssuer letsencrypt-issuer уже существует${NC}"
fi

# Проверка статуса ClusterIssuer
echo -e "${CYAN}Проверка статуса ClusterIssuer...${NC}"
kubectl get clusterissuer letsencrypt-issuer -o jsonpath='{.status.conditions[0].status}' 2>/dev/null

if [ $? -ne 0 ] || [ "$(kubectl get clusterissuer letsencrypt-issuer -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)" != "True" ]; then
    echo -e "${YELLOW}ClusterIssuer letsencrypt-issuer не готов или имеет ошибки${NC}"
    echo -e "${YELLOW}Проверьте статус:${NC}"
    kubectl describe clusterissuer letsencrypt-issuer
else
    echo -e "${GREEN}ClusterIssuer letsencrypt-issuer готов${NC}"
fi

# Проверка наличия сертификата для webui.eberil.ru
echo -e "${CYAN}Проверка наличия сертификата для webui.eberil.ru...${NC}"
if ! kubectl get certificate webui-eberil-ru-tls -n "${NAMESPACE_PROD}" &> /dev/null; then
    echo -e "${YELLOW}Сертификат webui-eberil-ru-tls не найден${NC}"
    echo -e "${YELLOW}Создание сертификата...${NC}"
    
    # Создание сертификата
    cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: webui-eberil-ru-tls
  namespace: ${NAMESPACE_PROD}
spec:
  secretName: webui-eberil-ru-tls
  issuerRef:
    name: letsencrypt-issuer
    kind: ClusterIssuer
  commonName: webui.eberil.ru
  dnsNames:
  - webui.eberil.ru
EOF
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка при создании сертификата${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Сертификат успешно создан${NC}"
else
    echo -e "${GREEN}Сертификат webui-eberil-ru-tls уже существует${NC}"
fi

# Проверка статуса сертификата
echo -e "${CYAN}Проверка статуса сертификата...${NC}"
kubectl get certificate webui-eberil-ru-tls -n "${NAMESPACE_PROD}" -o wide

echo -e "${CYAN}Подробная информация о сертификате:${NC}"
kubectl describe certificate webui-eberil-ru-tls -n "${NAMESPACE_PROD}"

echo -e "\n${GREEN}Настройка Let's Encrypt с Cloudflare DNS завершена${NC}"
echo -e "${YELLOW}Примечание: Выпуск сертификата может занять несколько минут${NC}"
echo -e "${YELLOW}Вы можете проверить статус сертификата командой:${NC}"
echo -e "${CYAN}kubectl describe certificate webui-eberil-ru-tls -n ${NAMESPACE_PROD}${NC}"