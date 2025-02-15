#!/bin/bash

# Цвета для вывода
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Функция для проверки наличия команды
check_command() {
 if ! command -v $1 &> /dev/null; then
   echo -e "${RED}Команда $1 не найдена. Устанавливаем...${NC}"
   return 1
 fi
 return 0
}

# Функция для установки curl если его нет
install_curl() {
 if ! check_command curl; then
   sudo apt-get update
   sudo apt-get install -y curl
 fi
}

# Функция установки Helm
install_helm() {
 echo -e "${CYAN}Установка Helm...${NC}"
 
 # Загрузка и установка Helm
 curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
 
 if ! check_command helm; then
   echo -e "${RED}Ошибка установки Helm${NC}"
   exit 1
 fi
}

# Функция добавления репозиториев
add_repositories() {
 echo -e "${CYAN}Добавление репозиториев Helm...${NC}"
 
 # Список репозиториев для добавления
 declare -A repos=(
   ["jetstack"]="https://charts.jetstack.io"
   ["bitnami"]="https://charts.bitnami.com/bitnami"
   ["prometheus-community"]="https://prometheus-community.github.io/helm-charts"
   ["ingress-nginx"]="https://kubernetes.github.io/ingress-nginx"
 )
 
 # Добавление каждого репозитория
 for repo in "${!repos[@]}"; do
   echo -e "${CYAN}Добавление репозитория $repo...${NC}"
   helm repo add "$repo" "${repos[$repo]}" || echo -e "${RED}Ошибка добавления репозитория $repo${NC}"
 done
 
 # Обновление репозиториев
 echo -e "${CYAN}Обновление репозиториев...${NC}"
 helm repo update
}

# Функция проверки установки
verify_installation() {
 echo -e "${CYAN}Проверка установки Helm...${NC}"
 
 if helm version; then
   echo -e "${GREEN}Helm успешно установлен!${NC}"
   echo -e "Версия Helm:"
   helm version
   echo -e "\nСписок репозиториев:"
   helm repo list
 else
   echo -e "${RED}Ошибка при проверке установки Helm${NC}"
   exit 1
 fi
}

# Основная функция
main() {
 echo -e "${YELLOW}Начинаем установку Helm...${NC}"
 
 # Проверка и установка curl
 install_curl
 
 # Проверка наличия Helm
 if ! check_command helm; then
   install_helm
 else
   echo -e "${GREEN}Helm уже установлен${NC}"
 fi
 
 # Добавление репозиториев
 add_repositories
 
 # Проверка установки
 verify_installation
 
 echo -e "${GREEN}Установка Helm завершена успешно!${NC}"
}

# Запуск скрипта
main