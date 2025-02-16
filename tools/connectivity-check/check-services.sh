#!/usr/bin/bash
#   ____ _               _    
#  / ___| |__   ___  ___| | __
# | |   | '_ \ / _ \/ __| |/ /
# | |___| | | |  __/ (__|   < 
#  \____|_| |_|\___|\___|_|\_\
#                    by @eberil
#
# Copyright (c)  2025 Mikhail Eberil
# This code is free! Share it, spread peace and technology!
# "Because monitoring should be thorough!"

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Загрузка общих переменных и баннеров
source "${REPO_ROOT}/tools/k8s-kind-setup/env.sh"
source "${REPO_ROOT}/tools/k8s-kind-setup/ascii_banners.sh"

# Отображение баннера при старте
check_banner
echo -e "\n${CYAN}Начинаем проверку сервисов...${NC}\n"

# Функция для форматированного вывода результатов
print_check_result() {
    local check_name=$1
    local status=$2
    local details=$3
    
    printf "${CYAN}%-30s${NC}" "$check_name"
    if [ "$status" = "OK" ]; then
        printf "${GREEN}%-10s${NC}" "$status"
    else
        printf "${RED}%-10s${NC}" "$status"
    fi
    echo -e "$details"
}

# Функция проверки DNS
check_dns() {
    echo -e "\n${YELLOW}[1/6] Проверка DNS резолвинга...${NC}"
    local domains=("$OLLAMA_HOST" "$WEBUI_HOST")
    
    for domain in "${domains[@]}"; do
        local ip=$(getent hosts "$domain" | awk '{ print $1 }')
        if [ -n "$ip" ]; then
            print_check_result "$domain" "OK" "→ $ip"
        else
            print_check_result "$domain" "FAIL" "DNS резолвинг не работает"
        fi
    done
}

# Функция проверки портов
check_ports() {
    echo -e "\n${YELLOW}[2/6] Проверка доступности портов...${NC}"
    local ports=(80 443)
    local hosts=("localhost" "$OLLAMA_HOST" "$WEBUI_HOST")
    
    for host in "${hosts[@]}"; do
        for port in "${ports[@]}"; do
            if nc -zv "$host" "$port" 2>/dev/null; then
                print_check_result "$host:$port" "OK" "Порт доступен"
            else
                print_check_result "$host:$port" "FAIL" "Порт недоступен"
            fi
        done
    done
}

# Функция проверки HTTPS
check_https() {
    echo -e "\n${YELLOW}[3/6] Проверка HTTPS endpoints...${NC}"
    local urls=("https://$WEBUI_HOST" "https://$OLLAMA_HOST")
    
    for url in "${urls[@]}"; do
        local status=$(curl -k -s -o /dev/null -w "%{http_code}" "$url")
        if [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ]; then
            print_check_result "$url" "OK" "HTTP $status"
        else
            print_check_result "$url" "FAIL" "HTTP $status"
        fi
    done
}

# Функция проверки подов
check_pods() {
    echo -e "\n${YELLOW}[4/6] Проверка статуса подов...${NC}"
    local namespaces=("$NAMESPACE_PROD" "$NAMESPACE_CERT_MANAGER" "$NAMESPACE_INGRESS")
    
    for ns in "${namespaces[@]}"; do
        echo -e "\n${CYAN}Namespace: $ns${NC}"
        kubectl get pods -n "$ns" -o wide
    done
}

# Функция проверки сертификатов
check_certificates() {
    echo -e "\n${YELLOW}[5/6] Проверка сертификатов...${NC}"
    
    echo -e "\n${CYAN}Certificates:${NC}"
    kubectl get certificates -n "$NAMESPACE_PROD"
    
    echo -e "\n${CYAN}TLS Secrets:${NC}"
    kubectl get secrets -n "$NAMESPACE_PROD" | grep tls
}

# Функция проверки Ingress
check_ingress() {
    echo -e "\n${YELLOW}[6/6] Проверка конфигурации Ingress...${NC}"
    
    echo -e "\n${CYAN}Ingress Resources:${NC}"
    kubectl get ingress -A
    
    echo -e "\n${CYAN}Ingress Controller Pods:${NC}"
    kubectl get pods -n "$NAMESPACE_INGRESS" -l app.kubernetes.io/component=controller
}

# Основная функция
main() {
    # Проверка наличия необходимых утилит
    local required_tools=("kubectl" "curl" "nc" "getent")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            echo -e "${RED}Ошибка: $tool не установлен${NC}"
            exit 1
        fi
    done
    
    # Запуск всех проверок
    check_dns
    check_ports
    check_https
    check_pods
    check_certificates
    check_ingress
    
    # Вывод итогового статуса
    echo -e "\n${GREEN}Проверка завершена!${NC}"
}

# Запуск скрипта
main