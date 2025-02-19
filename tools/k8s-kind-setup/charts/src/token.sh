#!/bin/bash

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Загрузка общих переменных и баннеров
source "${SCRIPT_DIR}/env"
source "${SCRIPT_DIR}/ascii_banners"

# Отображение баннера при старте
k8s_banner
echo ""

# Цвета для вывода
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Константы
NAMESPACE="kubernetes-dashboard"
SA_NAME="admin-user"

# Функция для проверки наличия команды
check_command() {
 if ! command -v $1 &> /dev/null; then
   echo -e "${RED}Ошибка: $1 не установлен${NC}"
   exit 1
 fi
}

# Функция проверки наличия необходимых компонентов
check_prerequisites() {
 echo -e "${CYAN}Проверка необходимых компонентов...${NC}"
 check_command kubectl
 
 # Проверка доступности кластера
 if ! kubectl cluster-info &> /dev/null; then
   echo -e "${RED}Ошибка: Нет доступа к кластеру Kubernetes${NC}"
   exit 1
 fi
}

# Функция проверки существования сервисного аккаунта
check_service_account() {
 if ! kubectl -n "$NAMESPACE" get serviceaccount "$SA_NAME" &> /dev/null; then
   echo -e "${RED}Ошибка: Сервисный аккаунт $SA_NAME не найден в namespace $NAMESPACE${NC}"
   echo -e "${YELLOW}Возможно, вам нужно установить Dashboard или создать сервисный аккаунт${NC}"
   exit 1
 fi
}

# Функция получения токена
get_token() {
 echo -e "${CYAN}Получение токена...${NC}"
 local token
 
 # Пробуем получить токен новым способом (для K8s >= 1.24)
 if token=$(kubectl -n "$NAMESPACE" create token "$SA_NAME" 2>/dev/null); then
   echo -e "${GREEN}Токен успешно получен!${NC}"
   echo -e "\nТокен для входа в Dashboard:\n${CYAN}$token${NC}"
   return 0
 fi
 
 # Если новый способ не сработал, пробуем старый (для K8s < 1.24)
 local secret_name
 secret_name=$(kubectl -n "$NAMESPACE" get serviceaccount "$SA_NAME" -o jsonpath='{.secrets[0].name}')
 if [ -n "$secret_name" ]; then
   token=$(kubectl -n "$NAMESPACE" get secret "$secret_name" -o jsonpath='{.data.token}' | base64 --decode)
   if [ -n "$token" ]; then
	 echo -e "${GREEN}Токен успешно получен!${NC}"
	 echo -e "\nТокен для входа в Dashboard:\n${CYAN}$token${NC}"
	 return 0
   fi
 fi
 
 echo -e "${RED}Ошибка: Не удалось получить токен${NC}"
 exit 1
}

# Функция вывода инструкций по использованию
print_usage_instructions() {
 echo -e "\n${YELLOW}Для доступа к Dashboard:${NC}"
 echo -e "1. Запустите: ${CYAN}kubectl proxy${NC}"
 echo -e "2. Откройте в браузере:"
 echo -e "${CYAN}http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/${NC}"
 echo -e "3. Используйте токен выше для входа"
}

# Основная функция
main() {
 echo -e "${YELLOW}Получение токена для Kubernetes Dashboard...${NC}"
 
 # Проверка prerequisites
 check_prerequisites
 
 # Проверка сервисного аккаунта
 check_service_account
 
 # Получение токена
 get_token
 
 # Вывод инструкций
 print_usage_instructions
}

# Запуск скрипта
main
