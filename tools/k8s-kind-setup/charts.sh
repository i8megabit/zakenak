#!/usr/bin/bash

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CHARTS_DIR="${REPO_ROOT}/helm-charts"

# Добавление пути репозитория в PATH
export PATH="${REPO_ROOT}/tools/k8s-kind-setup:${REPO_ROOT}/tools/helm-setup:${REPO_ROOT}/tools/helm-deployer:${PATH}"

# Загрузка общих переменных
source "${SCRIPT_DIR}/env"

# Функция получения списка чартов
get_charts() {
	local charts=()
	for chart_dir in "${CHARTS_DIR}"/*; do
		if [ -f "${chart_dir}/Chart.yaml" ]; then
			charts+=("$(basename "${chart_dir}")")
		fi
	done
	echo "${charts[@]}"
}

# Функция генерации списка чартов для меню
generate_charts_menu() {
	local charts=($1)
	echo "Чарты:"
	echo "  all          - Все чарты"
	for chart in "${charts[@]}"; do
		# Получаем описание из Chart.yaml если оно есть
		local description=""
		if [ -f "${CHARTS_DIR}/${chart}/Chart.yaml" ]; then
			description=$(grep "description:" "${CHARTS_DIR}/${chart}/Chart.yaml" | cut -d'"' -f2 || echo "")
		fi
		printf "  %-12s - %s\n" "$chart" "${description:-$chart}"
	done
}

# Функция вывода справки
usage() {
	local charts=($(get_charts))
	
	echo "Использование: $0 [опции] <действие> <чарт>"
	echo ""
	echo "Действия:"
	echo "  install   - Установить чарт"
	echo "  upgrade   - Обновить чарт"
	echo "  uninstall - Удалить чарт"
	echo "  list      - Показать список установленных чартов"
	echo ""
	generate_charts_menu "$(get_charts)"
	echo ""
	echo "Опции:"
	echo "  -n, --namespace <namespace>  - Использовать указанный namespace"
	echo "  -v, --version <version>      - Использовать указанную версию"
	echo "  -f, --values <file>          - Использовать дополнительный values файл"
	echo "  -h, --help                   - Показать эту справку"
	exit 1
}

# Функция установки чарта
install_chart() {
	local chart=$1
	local namespace=${2:-$NAMESPACE_PROD}
	local version=$3
	local values=$4
	
	local chart_path="${CHARTS_DIR}/${chart}"
	
	if [ ! -d "$chart_path" ]; then
		echo -e "${RED}Ошибка: Чарт $chart не найден${NC}"
		exit 1
	fi
	
	echo -e "${CYAN}Установка чарта $chart...${NC}"
	helm upgrade --install "$chart" "$chart_path" \
		--namespace "$namespace" \
		--create-namespace \
		${version:+--version "$version"} \
		${values:+--values "$values"} \
		--wait
	
	check_error "Не удалось установить чарт $chart"
}

# Парсинг аргументов
NAMESPACE=""
VERSION=""
VALUES=""
ACTION=""
CHART=""

while [[ $# -gt 0 ]]; do
	case $1 in
		-n|--namespace)
			NAMESPACE="$2"
			shift 2
			;;
		-v|--version)
			VERSION="$2"
			shift 2
			;;
		-f|--values)
			VALUES="$2"
			shift 2
			;;
		-h|--help)
			usage
			;;
		*)
			if [ -z "$ACTION" ]; then
				ACTION="$1"
			elif [ -z "$CHART" ]; then
				CHART="$1"
			else
				echo "Неизвестный аргумент: $1"
				usage
			fi
			shift
			;;
	esac
done

# Проверка обязательных аргументов
if [ -z "$ACTION" ] || [ -z "$CHART" ]; then
	echo "Необходимо указать действие и чарт"
	usage
fi

# Получение списка доступных чартов
AVAILABLE_CHARTS=($(get_charts))

# Выполнение действия
case $ACTION in
	"install"|"upgrade")
		if [ "$CHART" = "all" ]; then
			for chart in "${AVAILABLE_CHARTS[@]}"; do
				install_chart "$chart" "$NAMESPACE" "$VERSION" "$VALUES"
			done
		else
			install_chart "$CHART" "$NAMESPACE" "$VERSION" "$VALUES"
		fi
		;;
	"uninstall")
		if [ "$CHART" = "all" ]; then
			for chart in "${AVAILABLE_CHARTS[@]}"; do
				helm uninstall "$chart" --namespace "${NAMESPACE:-$NAMESPACE_PROD}"
			done
		else
			helm uninstall "$CHART" --namespace "${NAMESPACE:-$NAMESPACE_PROD}"
		fi
		;;
	"list")
		helm list --all-namespaces
		;;
	*)
		echo "Неизвестное действие: $ACTION"
		usage
		;;
esac