#!/bin/bash

# Цвета для вывода
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Глобальные переменные
CHARTS_DIR=""
ENVIRONMENT="default"
DEBUG=false

# Функция для проверки существования файла
check_file_exists() {
 if [ -f "$1" ]; then
   return 0
 fi
 return 1
}

# Функция проверки наличия необходимых инструментов
check_prerequisites() {
 local tools=("helm" "kubectl" "yq")
 for tool in "${tools[@]}"; do
   if ! command -v "$tool" &> /dev/null; then
	 echo -e "${RED}Ошибка: $tool не установлен${NC}"
	 exit 1
   fi
 done
}

# Функция получения значения из values файла
get_value() {
 local file=$1
 local key=$2
 local default=$3
 
 if check_file_exists "$file"; then
   local value=$(yq eval ".$key" "$file")
   if [ "$value" != "null" ] && [ -n "$value" ]; then
	 echo "$value"
	 return 0
   fi
 fi
 echo "$default"
}

# Функция деплоя чарта
deploy_chart() {
 local chart_path=$1
 local chart_name=$(basename "$chart_path")
 
 echo -e "${CYAN}Обработка чарта: $chart_name${NC}"
 
 # Получаем значения из values файлов
 local global_values="$CHARTS_DIR/values.yaml"
 local chart_values="$chart_path/values.yaml"
 local env_values="$chart_path/values.$ENVIRONMENT.yaml"
 
 # Получаем имя релиза и namespace
 local release_name=$(get_value "$chart_values" "release.name" "$chart_name")
 local namespace=$(get_value "$chart_values" "release.namespace" "default")
 
 echo -e "Релиз: $release_name"
 echo -e "Namespace: $namespace"
 echo -e "Окружение: $ENVIRONMENT"

 # Создание namespace если не существует
 if ! kubectl get namespace "$namespace" &> /dev/null; then
   echo -e "${CYAN}Создание namespace $namespace...${NC}"
   kubectl create namespace "$namespace"
 fi

 # Формируем команду helm
 local helm_cmd="helm upgrade --install $release_name $chart_path --namespace $namespace"
 
 # Добавляем values файлы в порядке приоритета
 if check_file_exists "$global_values"; then
   helm_cmd="$helm_cmd -f $global_values"
 fi
 
 if check_file_exists "$chart_values"; then
   helm_cmd="$helm_cmd -f $chart_values"
 fi
 
 if check_file_exists "$env_values"; then
   helm_cmd="$helm_cmd -f $env_values"
 fi
 
 # Добавляем дополнительные флаги
 if [ "$DEBUG" = true ]; then
   helm_cmd="$helm_cmd --debug"
 fi

 echo -e "${CYAN}Выполняем деплой...${NC}"
 echo "Команда: $helm_cmd"
 
 if ! eval "$helm_cmd"; then
   echo -e "${RED}Ошибка: Деплой чарта $chart_name не удался${NC}"
   return 1
 fi

 echo -e "${GREEN}Чарт $chart_name успешно установлен${NC}"
 return 0
}

# Основная логика
main() {
 # Парсинг аргументов
 while [[ $# -gt 0 ]]; do
   case $1 in
	 -d|--charts-dir) CHARTS_DIR="$2"; shift 2 ;;
	 -e|--environment) ENVIRONMENT="$2"; shift 2 ;;
	 --debug) DEBUG=true; shift ;;
	 -h|--help)
	   echo "Использование: $0 [-d CHARTS_DIR] [-e ENVIRONMENT] [--debug]"
	   exit 0
	   ;;
	 *) echo "Неизвестная опция: $1"; exit 1 ;;
   esac
 done

 # Установка директории чартов по умолчанию
 if [ -z "$CHARTS_DIR" ]; then
   CHARTS_DIR="$(dirname $(dirname $0))/helm-charts"
 fi

 # Проверка существования директории чартов
 if [ ! -d "$CHARTS_DIR" ]; then
   echo -e "${RED}Ошибка: Директория чартов не найдена: $CHARTS_DIR${NC}"
   exit 1
 fi

 # Проверка prerequisites
 check_prerequisites

 echo -e "${YELLOW}Начинаем деплой чартов...${NC}"
 echo -e "Директория чартов: $CHARTS_DIR"
 echo -e "Окружение: $ENVIRONMENT"

# Функция получения порядка установки чартов
get_charts_order() {
 local charts_dir="$1"
 local order_file="$charts_dir/install-order.yaml"
 
 if check_file_exists "$order_file"; then
   # Изменяем способ чтения yaml файла
   yq '.charts[]' "$order_file"
   return 0
 fi
 
 # Если файл порядка не существует, просто листинг директорий
 ls -d "$charts_dir"/*/ | sort
}

 # Получаем список чартов для установки
 local charts=$(get_charts_order "$CHARTS_DIR")

 # Счетчики для статистики
 local success_count=0
 local total_charts=$(echo "$charts" | wc -l)

 # Устанавливаем каждый чарт
 for chart in $charts; do
   if [ -d "$CHARTS_DIR/$chart" ]; then
	 if deploy_chart "$CHARTS_DIR/$chart"; then
	   ((success_count++))
	 fi
   fi
 done

 echo -e "\n${GREEN}Деплой завершен. Успешно установлено $success_count из $total_charts чартов.${NC}"
}

# Запуск скрипта
main "$@"