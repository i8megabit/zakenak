#!/usr/bin/bash
#   ____ ___    ____ ____  
#  / ___|_ _|  / ___|  _ \ 
# | |    | |  | |   | | | |
# | |___ | |  | |___| |_| |
#  \____|___|  \____|____/ 
#                by @eberil
#
# Copyright (c) 2024 Mikhail Eberil
# CI/CD Helm Deployment Tool
# Version: 2.0.0

# Установка строгого режима
set -euo pipefail

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Загрузка общих переменных и баннеров
source "${REPO_ROOT}/tools/k8s-kind-setup/env"
source "${REPO_ROOT}/tools/k8s-kind-setup/ascii_banners"

# Значения по умолчанию
ENVIRONMENT=""
CHART_PATH=""
DEBUG=false
HELM_EXTRA_ARGS=""
ACTION="install"
VALIDATE=true
TIMEOUT="5m"
ATOMIC=true
WAIT=true

# Функция вывода справки
usage() {
	cat << EOF
Использование: $(basename $0) [опции]

CI/CD инструмент для автоматизированного деплоя Helm чартов

Опции:
	-e, --environment    Окружение для деплоя (также используется как namespace)
	-c, --chart         Путь к Helm чарту
	-d, --debug         Включить режим отладки
	-x, --extra-args    Дополнительные аргументы для helm upgrade
	-u, --uninstall     Удалить релиз
	-t, --timeout       Таймаут ожидания (по умолчанию: 5m)
	--no-atomic         Отключить атомарное развертывание
	--no-wait           Отключить ожидание готовности
	--no-validate       Отключить валидацию
	-h, --help          Показать эту справку

Примеры:
	# Установка в CI/CD:
	$(basename $0) -e prod -c ./helm-charts/my-chart --timeout 10m

	# Быстрая установка без ожидания:
	$(basename $0) -e dev -c ./helm-charts/my-chart --no-wait

	# Удаление с таймаутом:
	$(basename $0) -e prod -c ./helm-charts/my-chart -u -t 2m
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
	
	echo -e "${CYAN}Валидация чарта $chart_path...${NC}"
	
	# Проверка структуры чарта
	if [ ! -f "$chart_path/Chart.yaml" ]; then
		echo -e "${RED}Ошибка: Chart.yaml не найден в $chart_path${NC}"
		exit 1
	fi
	
	# Проверка синтаксиса values.yaml
	if [ -f "$chart_path/values.yaml" ]; then
		if ! yq eval '.' "$chart_path/values.yaml" > /dev/null; then
			echo -e "${RED}Ошибка: некорректный синтаксис в values.yaml${NC}"
			exit 1
		fi
	fi
	
	# Проверка шаблонов
	if ! helm template "$chart_path" > /dev/null; then
		echo -e "${RED}Ошибка: некорректные шаблоны в чарте${NC}"
		exit 1
	fi
	
	# Проверка lint
	if ! helm lint "$chart_path" > /dev/null; then
		echo -e "${RED}Ошибка: проверка lint не пройдена${NC}"
		exit 1
	fi
	
	echo -e "${GREEN}Валидация успешно пройдена${NC}"
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
		-u|--uninstall)
			ACTION="uninstall"
			shift
			;;
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

# Функция для инициализации зависимостей чарта
init_chart_dependencies() {
	local chart_path=$1
	echo -e "${CYAN}Инициализация зависимостей для чарта: $chart_path${NC}"
	
	if [ -f "$chart_path/Chart.yaml" ]; then
		# Извлекаем репозитории из Chart.yaml с помощью grep и awk
		while IFS= read -r line; do
			if [[ $line =~ repository:[[:space:]]*(.*) ]]; then
				local repo="${BASH_REMATCH[1]}"
				if [[ $repo == http* ]] || [[ $repo == https* ]]; then
					# Извлекаем имя репозитория из URL более надежным способом
					local repo_name
					repo_name=$(echo "$repo" | sed -E 's|^https?://||' | cut -d'.' -f1)
					# Для jetstack используем специальное имя
					if [[ $repo == *"jetstack"* ]]; then
						repo_name="jetstack"
					fi
					echo -e "${CYAN}Добавление репозитория: $repo_name - $repo${NC}"
					helm repo add "$repo_name" "$repo" || true
				fi
			fi
		done < "$chart_path/Chart.yaml"
		
		# Обновление репозиториев
		echo -e "${CYAN}Обновление репозиториев Helm...${NC}"
		helm repo update
		
		# Сборка зависимостей
		echo -e "${CYAN}Сборка зависимостей чарта...${NC}"
		helm dependency build "$chart_path"
	else
		echo -e "${YELLOW}Chart.yaml не найден в $chart_path${NC}"
	fi
}

# Функция деплоя чарта
deploy_chart() {
	local chart_path=$1
	
	# Валидация чарта если включена
	if [ "$VALIDATE" = true ]; then
		validate_chart "$chart_path"
	fi
	
	# Создание namespace если не существует
	ensure_namespace "$ENVIRONMENT"
	
	# Инициализация зависимостей перед деплоем
	init_chart_dependencies "$chart_path"
	
	# Определение values файла для окружения
	VALUES_FILE="${chart_path}/values-${ENVIRONMENT}.yaml"
	if [ ! -f "$VALUES_FILE" ]; then
		VALUES_FILE="${chart_path}/values.yaml"
	fi
	
	# Получение имени релиза
	RELEASE_NAME=$(yq eval '.release.name' "$VALUES_FILE" 2>/dev/null || basename "$chart_path")
	
	echo -e "${CYAN}Деплой чарта:${NC}"
	echo -e "Окружение: ${GREEN}$ENVIRONMENT${NC}"
	echo -e "Чарт: ${GREEN}$chart_path${NC}"
	echo -e "Values файл: ${GREEN}$VALUES_FILE${NC}"
	echo -e "Имя релиза: ${GREEN}$RELEASE_NAME${NC}"
	
	# Формирование команды helm
	local helm_cmd="helm upgrade --install $RELEASE_NAME $chart_path \
		--namespace $ENVIRONMENT \
		--values $VALUES_FILE \
		--timeout $TIMEOUT"

	# Добавление опциональных флагов
	[ "$ATOMIC" = true ] && helm_cmd+=" --atomic"
	[ "$WAIT" = true ] && helm_cmd+=" --wait"
	[ -n "$HELM_EXTRA_ARGS" ] && helm_cmd+=" $HELM_EXTRA_ARGS"
	
	# Выполнение деплоя
	if eval $helm_cmd; then
		echo -e "${GREEN}Деплой успешно завершен!${NC}"
		
		# Проверка статуса после деплоя
		if [ "$WAIT" = true ]; then
			echo -e "${CYAN}Проверка статуса подов...${NC}"
			kubectl get pods -n "$ENVIRONMENT" -l "app.kubernetes.io/instance=$RELEASE_NAME"
		fi
	else
		echo -e "${RED}Ошибка при выполнении деплоя${NC}"
		exit 1
	fi
}

# Функция удаления релиза
uninstall_chart() {
	local chart_path=$1
	
	# Определение values файла для окружения
	VALUES_FILE="${chart_path}/values-${ENVIRONMENT}.yaml"
	if [ ! -f "$VALUES_FILE" ]; then
		VALUES_FILE="${chart_path}/values.yaml"
	fi
	
	# Получение имени релиза из values файла или использование имени чарта
	RELEASE_NAME=$(yq eval '.release.name' "$VALUES_FILE" 2>/dev/null || basename "$chart_path")
	
	echo -e "${CYAN}Удаление релиза:${NC}"
	echo -e "Релиз: ${GREEN}$RELEASE_NAME${NC}"
	echo -e "Namespace: ${GREEN}$ENVIRONMENT${NC}"
	
	# Выполнение удаления
	if helm uninstall "$RELEASE_NAME" --namespace "$ENVIRONMENT"; then
		echo -e "${GREEN}Релиз успешно удален!${NC}"
	else
		echo -e "${RED}Ошибка при удалении релиза${NC}"
		exit 1
	fi
}

# Выполнение действия в зависимости от выбранной операции
if [ "$ACTION" = "uninstall" ]; then
	uninstall_chart "$CHART_PATH"
else
	deploy_chart "$CHART_PATH"
fi
