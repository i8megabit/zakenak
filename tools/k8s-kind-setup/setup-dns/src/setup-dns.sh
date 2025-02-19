#!/usr/bin/bash

# Загрузка переменных окружения
source "$(dirname "${BASH_SOURCE[0]}")/../../../env/src/env.sh"

echo -e "${CYAN}Настройка CoreDNS...${NC}"

# Применение конфигурации CoreDNS
if ! kubectl apply -f "$(dirname "${BASH_SOURCE[0]}")/coredns-custom.yaml"; then
	echo -e "${RED}Ошибка при применении конфигурации CoreDNS${NC}"
	exit 1
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

echo -e "${GREEN}CoreDNS успешно настроен!${NC}"
