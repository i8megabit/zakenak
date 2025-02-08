#!/bin/bash

# Цвета для вывода
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

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
 local values_file=$4
 local dry_run=$5
 local debug=$6

 local helm_cmd="helm upgrade --install $release_name $chart_path --namespace $namespace"
 
 # Добавляем values файл если указан
 if [ -n "$values_file" ]; then
   if [ ! -f "$values_file" ]; then
	 echo -e "${RED}Ошибка: Values файл не найден: $values_file${NC}"
	 exit 1
   fi
   helm_cmd="$helm_cmd -f $values_file"
 fi

 # Добавляем флаг dry-run если указан
 if [ "$dry_run" = true ]; then
   helm_cmd="$helm_cmd --dry-run"
 fi

 # Добавляем флаг debug если указан
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