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

# Функция вывода справки
usage() {
 echo "Использование: $0 [опции]"
 echo "Опции:"
 echo " -c, --chart CHART_PATH     Путь к чарту (обязательно)"
 echo " -r, --release NAME         Имя релиза (обязательно)"
 echo " -n, --namespace NAME       Namespace (по умолчанию: default)"
 echo " -f, --values FILE          Путь к values файлу"
 echo " -e, --env ENV              Окружение (dev/stage/prod)"
 echo " --dry-run                  Выполнить пробный запуск"
 echo " --debug                    Включить отладочный вывод"
 echo " -h, --help                 Показать эту справку"
 exit 1
}

# Функция проверки наличия необходимых инструментов
check_prerequisites() {
 local tools=("helm" "kubectl")
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

# Функция деплоя
deploy_chart() {
 local chart_path=$1
 local release_name=$2
 local namespace=$3
 local custom_values=$4
 local dry_run=$5
 local debug=$6

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

 # Добавляем кастомный values файл если указан (имеет наивысший приоритет)
 if [ -n "$custom_values" ]; then
   if check_file_exists "$custom_values"; then
     echo -e "${CYAN}Применяем кастомный values файл: $custom_values${NC}"
     helm_cmd="$helm_cmd -f $custom_values"
   else
     echo -e "${RED}Ошибка: Кастомный values файл не найден: $custom_values${NC}"
     exit 1
   fi
 fi

 # Добавляем флаги dry-run и debug
 if [ "$dry_run" = true ]; then
   helm_cmd="$helm_cmd --dry-run"
 fi
 if [ "$debug" = true ]; then
   helm_cmd="$helm_cmd --debug"
 fi

 echo -e "${CYAN}Выполняем деплой...${NC}"
 echo "Команда: $helm_cmd"
 
 if ! eval "$helm_cmd"; then
   echo -e "${RED}Ошибка: Деплой не удался${NC}"
   exit 1
 fi
}

# Основная логика
main() {
 local chart_path=""
 local release_name=""
 local namespace="default"
 local values_file=""
 local dry_run=false
 local debug=false

 # Парсинг аргументов
 while [[ $# -gt 0 ]]; do
   case $1 in
     -c|--chart) chart_path="$2"; shift 2 ;;
     -r|--release) release_name="$2"; shift 2 ;;
     -n|--namespace) namespace="$2"; shift 2 ;;
     -f|--values) values_file="$2"; shift 2 ;;
     --dry-run) dry_run=true; shift ;;
     --debug) debug=true; shift ;;
     -h|--help) usage ;;
     *) echo "Неизвестная опция: $1"; usage ;;
   esac
 done

 # Проверка обязательных параметров
 if [ -z "$chart_path" ] || [ -z "$release_name" ]; then
   echo -e "${RED}Ошибка: Не указаны обязательные параметры${NC}"
   usage
 fi

 # Проверка prerequisites
 check_prerequisites

 # Валидация чарта
 validate_chart "$chart_path"

 # Создание namespace если не существует
 if ! kubectl get namespace "$namespace" &> /dev/null; then
   echo -e "${CYAN}Создание namespace $namespace...${NC}"
   kubectl create namespace "$namespace"
 fi

 # Деплой чарта
 deploy_chart "$chart_path" "$release_name" "$namespace" "$values_file" "$dry_run" "$debug"

 echo -e "${GREEN}Деплой успешно завершен!${NC}"
}

# Запуск скрипта
main "$@"