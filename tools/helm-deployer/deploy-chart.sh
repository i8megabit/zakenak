#!/bin/bash

# Цвета для вывода
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

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

# Функция валидации чарта
validate_chart() {
 local chart_path=$1
 echo -e "${CYAN}Проверка чарта $chart_path...${NC}"
 if ! helm lint "$chart_path"; then
   echo -e "${RED}Ошибка: Проверка чарта не пройдена${NC}"
   exit 1
 fi
}

# Функция получения имени релиза из values
get_release_name() {
 local chart_path=$1
 local values_file="$chart_path/values.yaml"
 
 if check_file_exists "$values_file"; then
   local release_name=$(yq eval '.release.name' "$values_file")
   if [ "$release_name" != "null" ] && [ -n "$release_name" ]; then
     echo "$release_name"
     return 0
   fi
 fi
 
 # Если имя релиза не найдено в values, используем имя чарта
 basename "$chart_path"
}

# Функция получения namespace из values
get_namespace() {
 local chart_path=$1
 local values_file="$chart_path/values.yaml"
 
 if check_file_exists "$values_file"; then
   local namespace=$(yq eval '.release.namespace' "$values_file")
   if [ "$namespace" != "null" ] && [ -n "$namespace" ]; then
     echo "$namespace"
     return 0
   fi
 fi
 
 echo "default"
}

# Функция деплоя чарта
deploy_chart() {
 local chart_path=$1
 local release_name=$(get_release_name "$chart_path")
 local namespace=$(get_namespace "$chart_path")
 
 echo -e "${CYAN}Деплой чарта: $chart_path${NC}"
 echo -e "Релиз: $release_name"
 echo -e "Namespace: $namespace"

 # Создание namespace если не существует
 if ! kubectl get namespace "$namespace" &> /dev/null; then
   echo -e "${CYAN}Создание namespace $namespace...${NC}"
   kubectl create namespace "$namespace"
 fi

 # Базовая команда helm
 local helm_cmd="helm upgrade --install $release_name $chart_path --namespace $namespace"
 
 # Проверяем и добавляем глобальный values файл
 local global_values="$(dirname $(dirname $chart_path))/values.yaml"
 if check_file_exists "$global_values"; then
   echo -e "${CYAN}Найден глобальный values файл: $global_values${NC}"
   helm_cmd="$helm_cmd -f $global_values"
 fi

 # Проверяем и добавляем values файл чарта
 local chart_values="$chart_path/values.yaml"
 if check_file_exists "$chart_values"; then
   echo -e "${CYAN}Найден values файл чарта: $chart_values${NC}"
   helm_cmd="$helm_cmd -f $chart_values"
 fi

 echo -e "${CYAN}Выполняем деплой...${NC}"
 echo "Команда: $helm_cmd"
 
 if ! eval "$helm_cmd"; then
   echo -e "${RED}Ошибка: Деплой чарта $chart_path не удался${NC}"
   return 1
 fi

 return 0
}

# Функция получения порядка установки чартов
get_charts_order() {
 local charts_dir="$1"
 local order_file="$charts_dir/install-order.yaml"
 
 if check_file_exists "$order_file"; then
   yq eval '.charts[]' "$order_file"
   return 0
 fi
 
 # Если файл порядка не существует, просто листинг директорий
 ls -d "$charts_dir"/*/ | sort
}

# Основная логика
main() {
 local charts_dir="$(dirname $(dirname $0))/helm-charts"
 
 # Проверка prerequisites
 check_prerequisites

 echo -e "${YELLOW}Начинаем деплой всех чартов...${NC}"

 # Получаем список чартов в правильном порядке
 local charts=$(get_charts_order "$charts_dir")
 
 # Счетчик успешных установок
 local success_count=0
 local total_charts=$(echo "$charts" | wc -l)

 # Устанавливаем каждый чарт
 for chart in $charts; do
   if [ -d "$chart" ]; then
     echo -e "\n${YELLOW}Обработка чарта: $chart${NC}"
     
     # Валидация чарта
     validate_chart "$chart"
     
     # Деплой чарта
     if deploy_chart "$chart"; then
       ((success_count++))
       echo -e "${GREEN}Чарт $chart успешно установлен${NC}"
     else
       echo -e "${RED}Ошибка при установке чарта $chart${NC}"
     fi
   fi
 done

 echo -e "\n${GREEN}Деплой завершен. Успешно установлено $success_count из $total_charts чартов.${NC}"
}

# Запуск скрипта
main