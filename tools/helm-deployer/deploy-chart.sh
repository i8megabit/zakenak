#!/bin/bash

# Установка строгого режима
set -euo pipefail

# Цвета для вывода
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Значения по умолчанию
ENVIRONMENT=""
CHART_PATH=""
DEBUG=false
HELM_EXTRA_ARGS=""

# Функция вывода справки
usage() {
	cat << EOF
Использование: $(basename $0) [опции]

Опции:
	-e, --environment    Окружение для деплоя (также используется как namespace)
	-c, --chart         Путь к Helm чарту
	-d, --debug         Включить режим отладки
	-x, --extra-args    Дополнительные аргументы для helm upgrade
	-h, --help          Показать эту справку

Пример:
	$(basename $0) -e prod -c ./helm-charts/my-chart
	$(basename $0) -e dev --debug
EOF
	exit 1
}

# Функция проверки зависимостей
check_dependencies() {
	local deps=("kubectl" "helm" "yq")
	for dep in "${deps[@]}"; do
		if ! command -v $dep &> /dev/null; then
			echo -e "${RED}Ошибка: $dep не установлен${NC}"
			exit 1
		fi
	done
}

# Функция проверки подключения к кластеру
check_cluster() {
	if ! kubectl cluster-info &> /dev/null; then
		echo -e "${RED}Ошибка: нет подключения к кластеру Kubernetes${NC}"
		exit 1
	fi
}

# Функция валидации чарта
validate_chart() {
	local chart_path=$1
	if [ ! -f "$chart_path/Chart.yaml" ]; then
		echo -e "${RED}Ошибка: Chart.yaml не найден в $chart_path${NC}"
		exit 1
	fi
}

# Функция создания namespace если он не существует
ensure_namespace() {
	local namespace=$1
	if ! kubectl get namespace "$namespace" &> /dev/null; then
		echo -e "${CYAN}Создание namespace: $namespace${NC}"
		kubectl create namespace "$namespace"
	fi
}

# Парсинг аргументов
while [[ $# -gt 0 ]]; do
	case $1 in
		-e|--environment)
			ENVIRONMENT="$2"
			shift 2
			;;
		-c|--chart)
			CHART_PATH="$2"
			shift 2
			;;
		-d|--debug)
			DEBUG=true
			shift
			;;
		-x|--extra-args)
			HELM_EXTRA_ARGS="$2"
			shift 2
			;;
		-h|--help)
			usage
			;;
		*)
			echo -e "${RED}Неизвестный параметр: $1${NC}"
			usage
			;;
	esac
done

# Проверка обязательных параметров
if [ -z "$ENVIRONMENT" ]; then
	echo -e "${RED}Ошибка: не указано окружение (-e)${NC}"
	usage
fi

# Включение режима отладки если запрошено
if [ "$DEBUG" = true ]; then
	set -x
fi

# Проверка зависимостей и подключения к кластеру
check_dependencies
check_cluster

# Если путь к чарту не указан, ищем в стандартных местах
if [ -z "$CHART_PATH" ]; then
	if [ -d "./helm-charts" ]; then
		CHART_PATH="./helm-charts"
	elif [ -d "./charts" ]; then
		CHART_PATH="./charts"
	else
		echo -e "${RED}Ошибка: не указан путь к чарту и не найдены стандартные директории${NC}"
		exit 1
	fi
fi

# Валидация чарта
validate_chart "$CHART_PATH"

# Создание namespace если не существует
ensure_namespace "$ENVIRONMENT"

# Определение values файла для окружения
VALUES_FILE="$CHART_PATH/values-${ENVIRONMENT}.yaml"
if [ ! -f "$VALUES_FILE" ]; then
	VALUES_FILE="$CHART_PATH/values.yaml"
fi

# Получение имени релиза из values файла или использование имени чарта
RELEASE_NAME=$(yq eval '.release.name' "$VALUES_FILE" 2>/dev/null || basename "$CHART_PATH")

echo -e "${CYAN}Деплой чарта:${NC}"
echo -e "Окружение: ${GREEN}$ENVIRONMENT${NC}"
echo -e "Чарт: ${GREEN}$CHART_PATH${NC}"
echo -e "Values файл: ${GREEN}$VALUES_FILE${NC}"
echo -e "Имя релиза: ${GREEN}$RELEASE_NAME${NC}"

# Выполнение деплоя
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
	--namespace "$ENVIRONMENT" \
	--values "$VALUES_FILE" \
	--create-namespace \
	$HELM_EXTRA_ARGS

if [ $? -eq 0 ]; then
	echo -e "${GREEN}Деплой успешно завершен!${NC}"
else
	echo -e "${RED}Ошибка при выполнении деплоя${NC}"
	exit 1
fi