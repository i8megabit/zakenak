#!/usr/bin/bash
#  ____  _   _ ____  
# |  _ \| \ | / ___| 
# | | | |  \| \___ \ 
# | |_| | |\  |___) |
# |____/|_| \_|____/ 
#            by @eberil
#
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# This code is free! Share it, spread peace and technology!
# "Because DNS should just work!"

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

# Загрузка общих переменных и баннеров
source "${REPO_ROOT}/tools/k8s-kind-setup/env.sh"
source "${REPO_ROOT}/tools/k8s-kind-setup/ascii-banners/src/ascii_banners.sh"

# Отображение баннера при старте
dns_banner
echo ""

echo -e "${CYAN}Настройка CoreDNS...${NC}"

# Проверка наличия директории manifests
MANIFESTS_DIR="${SCRIPT_DIR}/manifests"
if [ ! -d "$MANIFESTS_DIR" ]; then
	echo -e "${RED}Ошибка: Директория manifests не найдена${NC}"
	exit 1
fi

# Применение конфигурации CoreDNS
kubectl apply -f "${MANIFESTS_DIR}/coredns-custom-config.yaml"
check_error "Не удалось применить конфигурацию CoreDNS"

kubectl apply -f "${MANIFESTS_DIR}/coredns-patch.yaml"
check_error "Не удалось применить патч CoreDNS"

# Перезапуск CoreDNS
echo -e "${CYAN}Перезапуск CoreDNS...${NC}"
kubectl rollout restart deployment coredns -n kube-system
check_error "Не удалось перезапустить CoreDNS"

# Ожидание готовности CoreDNS
echo -e "${CYAN}Ожидание готовности CoreDNS...${NC}"
kubectl rollout status deployment coredns -n kube-system --timeout=60s
check_error "Ошибка при ожидании готовности CoreDNS"

# Проверка DNS резолвинга
echo -e "${CYAN}Проверка DNS резолвинга...${NC}"
for domain in "$OLLAMA_HOST" "$WEBUI_HOST"; do
	echo -e "${YELLOW}Проверка резолвинга для $domain...${NC}"
	kubectl run -i --rm --restart=Never busybox --image=busybox:1.28 -- nslookup $domain
	check_error "Ошибка при проверке резолвинга для $domain"
done

echo -e "\n"
success_banner
echo -e "\n${GREEN}Настройка DNS успешно завершена!${NC}"