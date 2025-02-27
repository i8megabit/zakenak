#!/usr/bin/bash

# Загрузка переменных окружения
source "$(dirname "${BASH_SOURCE[0]}")/../../../env/src/env.sh"

echo -e "${CYAN}Настройка CoreDNS...${NC}"

# Применение конфигурации CoreDNS
# First check if the ConfigMap exists
if kubectl get configmap coredns -n kube-system &>/dev/null; then
    # If it exists, get the current ConfigMap and save it to a temporary file
    kubectl get configmap coredns -n kube-system -o yaml > /tmp/coredns-current.yaml
    
    # Apply the new configuration with --force flag to replace the existing ConfigMap
    if ! kubectl apply -f "$(dirname "${BASH_SOURCE[0]}")/coredns-custom.yaml" --force; then
        echo -e "${RED}Ошибка при применении конфигурации CoreDNS${NC}"
        exit 1
    fi
else
    # If it doesn't exist, create it with --save-config to ensure the annotation is set
    if ! kubectl apply -f "$(dirname "${BASH_SOURCE[0]}")/coredns-custom.yaml" --save-config; then
        echo -e "${RED}Ошибка при применении конфигурации CoreDNS${NC}"
        exit 1
    fi
fi

# Применение конфигурации coredns-custom-config
echo -e "${CYAN}Применение конфигурации coredns-custom-config...${NC}"
if kubectl get configmap coredns-custom -n kube-system &>/dev/null; then
    # If it exists, get the current ConfigMap and save it to a temporary file
    kubectl get configmap coredns-custom -n kube-system -o yaml > /tmp/coredns-custom-current.yaml
    
    # Apply the new configuration with --force flag to replace the existing ConfigMap
    if ! kubectl apply -f "$(dirname "${BASH_SOURCE[0]}")/manifests/coredns-custom-config.yaml" --force; then
        echo -e "${RED}Ошибка при применении конфигурации coredns-custom-config${NC}"
        exit 1
    fi
else
    # If it doesn't exist, create it with --save-config to ensure the annotation is set
    if ! kubectl apply -f "$(dirname "${BASH_SOURCE[0]}")/manifests/coredns-custom-config.yaml" --save-config; then
        echo -e "${RED}Ошибка при применении конфигурации coredns-custom-config${NC}"
        exit 1
    fi
fi

# Перезапуск CoreDNS для применения изменений
echo -e "${CYAN}Перезапуск CoreDNS...${NC}"
kubectl rollout restart deployment/coredns -n kube-system

# Ожидание готовности CoreDNS с использованием функции wait_for_deployment
echo -e "${CYAN}Ожидание готовности CoreDNS...${NC}"
if ! wait_for_deployment "kube-system" "coredns" 300 5; then
    echo -e "${RED}Ошибка при ожидании готовности CoreDNS${NC}"
    exit 1
fi

# Проверка DNS резолвинга
echo -e "${CYAN}Проверка DNS резолвинга...${NC}"
if ! kubectl run -it --rm --restart=Never --image=busybox:1.28 dns-test -- nslookup dashboard.prod.local; then
    echo -e "${YELLOW}Предупреждение: Проблемы с резолвингом dashboard.prod.local${NC}"
    echo -e "${YELLOW}Проверьте конфигурацию CoreDNS и IP-адреса в переменных окружения${NC}"
fi

echo -e "${GREEN}CoreDNS успешно настроен!${NC}"