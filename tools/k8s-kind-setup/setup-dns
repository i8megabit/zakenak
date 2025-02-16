#!/usr/bin/bash

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Загрузка общих переменных
source "${SCRIPT_DIR}/env"

echo -e "${CYAN}Настройка CoreDNS...${NC}"

# Применение конфигурации CoreDNS
kubectl apply -f "${SCRIPT_DIR}/manifests/coredns-custom-config.yaml"
kubectl apply -f "${SCRIPT_DIR}/manifests/coredns-patch.yaml"

# Перезапуск CoreDNS
kubectl rollout restart deployment coredns -n kube-system
check_error "Не удалось настроить CoreDNS"

# Ожидание готовности CoreDNS
kubectl rollout status deployment coredns -n kube-system --timeout=60s
check_error "Ошибка при ожидании готовности CoreDNS"

# Проверка DNS резолвинга
echo -e "${CYAN}Проверка DNS резолвинга...${NC}"
for domain in "$OLLAMA_HOST" "$WEBUI_HOST"; do
    echo "Проверка резолвинга для $domain..."
    kubectl run -i --rm --restart=Never busybox --image=busybox:1.28 -- nslookup $domain
done

echo -e "${GREEN}Настройка DNS успешно завершена!${NC}"