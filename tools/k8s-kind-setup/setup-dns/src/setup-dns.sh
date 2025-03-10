#!/usr/bin/bash

# Загрузка переменных окружения
source "$(dirname "${BASH_SOURCE[0]}")/../../../env/src/env.sh"

echo -e "${CYAN}Настройка CoreDNS...${NC}"

# Применение конфигурации CoreDNS
# First check if the ConfigMap exists
if kubectl get configmap coredns -n kube-system &>/dev/null; then
    # If it exists, apply the new configuration with --save-config flag to ensure the annotation is set
    if ! kubectl apply -f "$(dirname "${BASH_SOURCE[0]}")/coredns-custom.yaml" --save-config; then
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
    # If it exists, apply the new configuration with --save-config flag to ensure the annotation is set
    if ! kubectl apply -f "$(dirname "${BASH_SOURCE[0]}")/manifests/coredns-custom-config.yaml" --save-config; then
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

# Определение режима сети WSL2
NETWORK_MODE=$(detect_wsl_network_mode 2>/dev/null || echo "NAT")
echo -e "${CYAN}Обнаружен режим сети WSL2: ${NETWORK_MODE}${NC}"
echo -e "${CYAN}Используемый IP для DNS: ${OLLAMA_IP}${NC}"

# Проверка резолвинга для всех сервисов
for service in dashboard ollama webui; do
    echo -e "${CYAN}Проверка резолвинга ${service}.prod.local...${NC}"
    if ! kubectl run -it --rm --restart=Never --image=busybox:1.28 dns-test-${service} -- nslookup ${service}.prod.local; then
        echo -e "${YELLOW}Предупреждение: Проблемы с резолвингом ${service}.prod.local${NC}"
    else
        echo -e "${GREEN}Резолвинг ${service}.prod.local успешен${NC}"
    fi
done

# Проверка доступа к сервисам через curl
echo -e "${CYAN}Проверка доступа к сервисам...${NC}"
if kubectl run -it --rm --restart=Never --image=curlimages/curl curl-test -- curl -s -o /dev/null -w "%{http_code}" -m 5 http://${INGRESS_IP}; then
    echo -e "${GREEN}Доступ к сервисам через IP успешен${NC}"
else
    echo -e "${YELLOW}Предупреждение: Проблемы с доступом к сервисам через IP${NC}"
    echo -e "${YELLOW}Это нормально, если сервисы еще не развернуты${NC}"
fi

echo -e "${CYAN}Проверка DNS завершена${NC}"

# Check if running in WSL
if grep -q "microsoft" /proc/version || grep -q "WSL" /proc/version; then
    echo -e "${CYAN}Обнаружено WSL окружение. Настройка DNS для Windows...${NC}"
    
    # Inform about Windows DNS configuration
    echo -e "${YELLOW}ВАЖНО: Для доступа к сервисам из Windows необходимо настроить DNS.${NC}"
    echo -e "${YELLOW}В Windows домены *.prod.local не будут доступны без дополнительной настройки.${NC}"
    echo -e "${CYAN}Для настройки DNS в Windows выполните:${NC}"
    echo -e "${GREEN}./update-windows-dns.sh${NC}"
    echo -e "${CYAN}или следуйте инструкциям в README-WINDOWS-DNS.md${NC}"
    
    # Make the scripts executable
    chmod +x "$(dirname "${BASH_SOURCE[0]}")/update-windows-dns.sh" 2>/dev/null || true
    chmod +x "$(dirname "${BASH_SOURCE[0]}")/update-windows-hosts.ps1" 2>/dev/null || true
fi

echo -e "${GREEN}CoreDNS успешно настроен!${NC}"