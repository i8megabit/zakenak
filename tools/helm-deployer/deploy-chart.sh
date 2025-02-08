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

# Функция проверки валидности чарта
validate_chart() {
 local chart_path=$1
 
 # Проверяем наличие Chart.yaml
 if [ ! -f "$chart_path/Chart.yaml" ]; then
   echo -e "${RED}Ошибка: Chart.yaml не найден в $chart_path${NC}"
   return 1
 fi
 
 # Проверяем валидность чарта
 if ! helm lint "$chart_path" &>/dev/null; then
   echo -e "${RED}Ошибка: Проверка чарта не пройдена для $chart_path${NC}"
   return 1
 fi
 
 return 0
}

# Функция получения значения из values файла
get_value() {
 local file=$1
 local key=$2
 local default=$3
 
 if [ -f "$file" ]; then
   local value
   value=$(yq eval ".$key" "$file" 2>/dev/null)
   if [ "$?" -eq 0 ] && [ "$value" != "null" ] && [ -n "$value" ]; then
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
 
 # Проверяем валидность чарта
 if ! validate_chart "$chart_path"; then
   return 1
 fi
 
 # Получаем значения из values файлов
 local global_values="$CHARTS_DIR/values.yaml"
 local chart_values="$chart_path/values.yaml"
 local env_values="$chart_path/values.$ENVIRONMENT.yaml"
 
 # Получаем имя релиза и namespace
 local release_name=$(get_value "$chart_values" "release.name" "$chart_name")
 local namespace=$(get_value "$chart_values" "release.namespace" "$ENVIRONMENT")
 
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
 [ -f "$global_values" ] && helm_cmd="$helm_cmd -f $global_values"
 [ -f "$chart_values" ] && helm_cmd="$helm_cmd -f $chart_values"
 [ -f "$env_values" ] && helm_cmd="$helm_cmd -f $env_values"

 echo -e "${CYAN}Выполняем деплой...${NC}"
 echo "Команда: $helm_cmd"
 
 if ! eval "$helm_cmd"; then
   echo -e "${RED}Ошибка: Деплой чарта $chart_name не удался${NC}"
   return 1
 fi

 echo -e "${GREEN}Чарт $chart_name успешно установлен${NC}"
 return 0
}

# Функция получения порядка установки чартов
get_charts_order() {
 local charts_dir="$1"
 local order_file="$charts_dir/install-order.yaml"
 local charts=""
 
 echo -e "${CYAN}Поиск чартов в директории: $charts_dir${NC}"
 
 if [ -f "$order_file" ]; then
   echo -e "${CYAN}Найден файл install-order.yaml${NC}"
   while IFS= read -r chart_name; do
     # Пропускаем пустые строки и комментарии
     [[ -z "$chart_name" || "$chart_name" =~ ^[[:space:]]*# ]] && continue
     
     # Убираем начальный дефис и пробелы
     chart_name=$(echo "$chart_name" | sed -e 's/^[[:space:]]*-[[:space:]]*//')
     local chart_path="$charts_dir/$chart_name"
     
     echo -e "${CYAN}Проверка чарта: $chart_path${NC}"
     
     if [ -d "$chart_path" ] && [ -f "$chart_path/Chart.yaml" ]; then
       echo -e "${GREEN}Найден валидный чарт: $chart_name${NC}"
       charts+="$chart_path"$'\n'
     else
       echo -e "${YELLOW}Пропуск $chart_name: не найден Chart.yaml${NC}"
     fi
   done < <(yq e '.charts[]' "$order_file" 2>/dev/null)
 else
   echo -e "${YELLOW}Файл install-order.yaml не найден, поиск чартов в директории${NC}"
   while IFS= read -r dir; do
     if [ -f "$dir/Chart.yaml" ]; then
       echo -e "${GREEN}Найден валидный чарт: $(basename "$dir")${NC}"
       charts+="$dir"$'\n'
     else
       echo -e "${YELLOW}Пропуск $(basename "$dir"): не найден Chart.yaml${NC}"
     fi
   done < <(find "$charts_dir" -mindepth 1 -maxdepth 1 -type d)
 fi

 if [ -z "$charts" ]; then
   echo -e "${RED}Ошибка: Не найдено валидных чартов в $charts_dir${NC}"
   return 1
 fi

 echo "$charts"
}

# Основная логика
main() {
 local charts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/helm-charts"
 
 # Проверка prerequisites
 check_prerequisites

 echo -e "${YELLOW}Начинаем деплой чартов...${NC}"
 echo -e "Директория чартов: $charts_dir"
 echo -e "Окружение: $ENVIRONMENT"

 # Проверка существования директории чартов
 if [ ! -d "$charts_dir" ]; then
   echo -e "${RED}Ошибка: Директория чартов не найдена: $charts_dir${NC}"
   exit 1
 fi

 # Получаем список чартов
 local charts=$(get_charts_order "$charts_dir")
 if [ $? -ne 0 ]; then
   exit 1
 fi

 # Счетчики для статистики
 local success_count=0
 local total_charts=$(echo "$charts" | grep -c '^' || echo 0)

 echo -e "${CYAN}Найдено чартов для установки: $total_charts${NC}"

 # Устанавливаем каждый чарт
 while IFS= read -r chart; do
   [ -z "$chart" ] && continue
   
   if deploy_chart "$chart"; then
     ((success_count++))
   fi
 done <<< "$charts"

 echo -e "\n${GREEN}Деплой завершен. Успешно установлено $success_count из $total_charts чартов.${NC}"
}

# Запуск скрипта
main "$@"