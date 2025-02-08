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
 
 # Проверяем наличие Chart.yaml
 if [ ! -f "$chart_path/Chart.yaml" ]; then
   echo -e "${RED}Ошибка: Chart.yaml не найден в $chart_path${NC}"
   return 1
 fi
 
 # Получаем значения из values файлов
 local global_values="$CHARTS_DIR/values.yaml"
 local chart_values="$chart_path/values.yaml"
 local env_values="$chart_path/values.$ENVIRONMENT.yaml"
 
 # Получаем имя релиза и namespace из values
 local release_name=$(yq -r '.release.name // ""' "$chart_values" 2>/dev/null || echo "$chart_name")
 local namespace=$(yq -r '.release.namespace // "default"' "$chart_values" 2>/dev/null)
 
 echo -e "Релиз: $release_name"
 echo -e "Namespace: $namespace"

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

# Основная логика
main() {
 # Определяем путь к корню проекта и директории чартов
 CHARTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/helm-charts"
 ENVIRONMENT=${ENVIRONMENT:-"default"}


 # Проверка prerequisites
 check_prerequisites

 echo -e "${YELLOW}Начинаем деплой всех чартов...${NC}"
 echo -e "Директория чартов: $CHARTS_DIR"

 # Проверка существования директории чартов
 if [ ! -d "$CHARTS_DIR" ]; then
   echo -e "${RED}Ошибка: Директория чартов не найдена: $CHARTS_DIR${NC}"
   echo -e "${YELLOW}Убедитесь, что директория helm-charts существует в корне проекта${NC}"
   exit 1
 fi

 echo -e "Окружение: $ENVIRONMENT"

# Функция получения списка чартов
get_charts() {
 local charts_dir="$1"
 local order_file="$charts_dir/install-order.yaml"
 local charts=""

 echo -e "${CYAN}Поиск чартов в директории: $charts_dir${NC}"

 if check_file_exists "$order_file"; then
   echo -e "${CYAN}Найден файл порядка установки: $order_file${NC}"
   while IFS= read -r line; do
     # Пропускаем комментарии и пустые строки
     [[ "$line" =~ ^[[:space:]]*# ]] && continue
     [[ -z "${line// }" ]] && continue
     
     # Извлекаем имя чарта и проверяем его существование
     local chart_name=$(echo "$line" | sed -e 's/^[[:space:]]*-[[:space:]]*//')
     local chart_path="$charts_dir/$chart_name"
     
     if [ -d "$chart_path" ]; then
       echo -e "${CYAN}Добавлен чарт: $chart_name${NC}"
       charts+="$chart_path"$'\n'
     else
       echo -e "${YELLOW}Предупреждение: Директория чарта не найдена: $chart_path${NC}"
     fi
   done < <(yq -r '.charts[]' "$order_file" 2>/dev/null)
 else
   echo -e "${YELLOW}Файл порядка установки не найден, используем все поддиректории${NC}"
   while IFS= read -r chart_path; do
     if [ -d "$chart_path" ]; then
       echo -e "${CYAN}Добавлен чарт: $(basename "$chart_path")${NC}"
       charts+="$chart_path"$'\n'
     fi
   done < <(find "$charts_dir" -mindepth 1 -maxdepth 1 -type d | sort)
 fi

 if [ -z "$charts" ]; then
   echo -e "${RED}Ошибка: Не найдено чартов для установки${NC}"
   exit 1
 fi

 echo "$charts"
}

# Получаем список чартов
local charts=$(get_charts "$CHARTS_DIR")

# Счетчики для статистики
local success_count=0
local total_charts=$(echo "$charts" | grep -c '^' || echo 0)

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