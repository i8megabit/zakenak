#!/usr/bin/bash
#  _____ _   ___     __ 
# | ____| \ | \ \   / / 
# |  _| |  \| |\ \ / /  
# | |___| |\  | \ V /   
# |_____|_| \_|  \_/    
#              by @eberil
#
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# Environment Configuration
# Version: 1.0.0
#
# HUJAK-HUJAK PRODUCTION PRESENTS...
# "Because environment variables should be fun"

# Цветовые коды для вывода
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# Переменные окружения для кластера
export CLUSTER_NAME="kind"
export NAMESPACE_PROD="prod"
export NAMESPACE_INGRESS="ingress-nginx"
export NAMESPACE_CERT_MANAGER="cert-manager"

# Переменные для хостов сервисов
export OLLAMA_HOST="ollama.prod.local"
export WEBUI_HOST="webui.prod.local"

# Переменные для релизов
export RELEASE_CERT_MANAGER="cert-manager"
export RELEASE_INGRESS="ingress-nginx"

# Переменные для GPU
export NVIDIA_DRIVER_VERSION="535.104.05"
export CUDA_VERSION="12.8"
export GPU_MEMORY_LIMIT="8Gi"
export GPU_LAYERS="43"

# Переменные для сертификатов
export CERT_VALIDITY_DURATION="8760h"  # 1 год
export CERT_RENEW_BEFORE="720h"       # 30 дней
export CA_ORGANIZATION="DevSecMLOps"
export CA_COMMON_NAME="Local CA"

# Переменные для мониторинга
export MONITORING_ENABLED="true"
export LOG_RETENTION_DAYS="30"
export METRICS_SCRAPE_INTERVAL="15s"

# Функция проверки ошибок
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}$1${NC}"
        exit 1
    fi
}

# Функция ожидания готовности подов
wait_for_pods() {
    local namespace=$1
    local selector=$2
    local timeout=300

    echo -e "${CYAN}Ожидание готовности подов в namespace $namespace...${NC}"
    kubectl wait --for=condition=Ready pods -l $selector -n $namespace --timeout=${timeout}s
    check_error "Превышено время ожидания готовности подов"
}

# Функция ожидания готовности CRDs
wait_for_crds() {
    local timeout=60
    for crd in "$@"; do
        echo -e "${CYAN}Ожидание готовности CRD $crd...${NC}"
        kubectl wait --for=condition=established crd/$crd --timeout=${timeout}s
        check_error "Превышено время ожидания готовности CRD $crd"
    done
}
