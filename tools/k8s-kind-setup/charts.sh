#!/usr/bin/bash
#   _____ _                _       
#  / ____| |              | |      
# | |    | |__   __ _ _ __| |_ ___ 
# | |    | '_ \ / _` | '__| __/ __|
# | |____| | | | (_| | |  | |_\__ \
#  \_____|_| |_|\__,_|_|   \__|___/
#                         by @eberil
#
# Copyright (c)  2025 Mikhail Eberil
# Helm Charts Management Tool
# Version: 1.2.0
#
# HUJAK-HUJAK PRODUCTION PRESENTS...
# "Because managing charts shouldn't be a pain"

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CHARTS_DIR="${REPO_ROOT}/helm-charts"

# Загрузка общих переменных и баннеров
source "${SCRIPT_DIR}/env"
source "${SCRIPT_DIR}/ascii_banners"

# Отображение баннера при старте
charts_banner
echo ""

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

# Функция генерации цветного меню чартов
generate_charts_menu() {
    local charts=($1)
    echo -e "${CYAN}Доступные чарты:${NC}"
    echo -e "${GREEN}  all          ${YELLOW}-${NC} Все чарты"
    for chart in "${charts[@]}"; do
        # Получаем описание из Chart.yaml если оно есть
        local description=""
        if [ -f "${CHARTS_DIR}/${chart}/Chart.yaml" ]; then
            description=$(grep "description:" "${CHARTS_DIR}/${chart}/Chart.yaml" | cut -d'"' -f2 || echo "")
        fi
        printf "${GREEN}  %-12s ${YELLOW}-${NC} %s\n" "$chart" "${description:-$chart}"
    done
}

# Функция вывода справки
usage() {
    local charts=($(get_charts))
    
    echo -e "${CYAN}Использование:${NC} $0 ${YELLOW}[опции]${NC} ${GREEN}<действие>${NC} ${GREEN}<чарт>${NC}"
    echo ""
    echo -e "${CYAN}Действия:${NC}"
    echo -e "${GREEN}  install        ${YELLOW}-${NC} Установить чарт"
    echo -e "${GREEN}  upgrade        ${YELLOW}-${NC} Обновить чарт"
    echo -e "${GREEN}  uninstall      ${YELLOW}-${NC} Удалить чарт"
    echo -e "${GREEN}  list           ${YELLOW}-${NC} Показать список установленных чартов"
    echo -e "${GREEN}  dashboard-token${YELLOW}-${NC} Получить токен для Kubernetes Dashboard"
    echo ""
    generate_charts_menu "$(get_charts)"
    echo ""
    echo -e "${CYAN}Опции:${NC}"
    echo -e "${GREEN}  -n, --namespace ${YELLOW}<namespace>${NC}  - Использовать указанный namespace"
    echo -e "${GREEN}  -v, --version ${YELLOW}<version>${NC}      - Использовать указанную версию"
    echo -e "${GREEN}  -f, --values ${YELLOW}<file>${NC}          - Использовать дополнительный values файл"
    echo -e "${GREEN}  -h, --help${NC}                   - Показать эту справку"
    exit 1
}

# Функция установки/обновления чарта
install_chart() {
    local action=$1
    local chart=$2
    local namespace=${3:-$NAMESPACE_PROD}
    local version=$4
    local values_file=$5
    
    # Проверка существования чарта
    if [ ! -d "${CHARTS_DIR}/${chart}" ]; then
        echo -e "${RED}Ошибка: Чарт ${chart} не найден${NC}"
        exit 1
    }
    
    # Формирование команды helm
    local helm_cmd="helm ${action} ${chart} ${CHARTS_DIR}/${chart}"
    helm_cmd+=" --namespace ${namespace} --create-namespace"
    
    # Добавление версии и values если указаны
    [ -n "$version" ] && helm_cmd+=" --version ${version}"
    [ -n "$values_file" ] && helm_cmd+=" -f ${values_file}"
    
    echo -e "${CYAN}Выполняется ${action} чарта ${chart}...${NC}"
    eval $helm_cmd
    
    if [ $? -eq 0 ]; then
        echo -e "\n"
        success_banner
        echo -e "\n${GREEN}${action^} чарта ${chart} успешно завершен${NC}"
    else
        echo -e "\n"
        error_banner
        echo -e "\n${RED}Ошибка при выполнении ${action} чарта ${chart}${NC}"
        exit 1
    fi
}

# Обработка параметров командной строки
namespace=""
version=""
values_file=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -n|--namespace)
            namespace="$2"
            shift 2
            ;;
        -v|--version)
            version="$2"
            shift 2
            ;;
        -f|--values)
            values_file="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

# Проверка наличия действия и чарта
if [ $# -lt 2 ]; then
    usage
fi

action=$1
chart=$2

case $action in
    install|upgrade|uninstall)
        if [ "$chart" = "all" ]; then
            charts=($(get_charts))
            for c in "${charts[@]}"; do
                install_chart $action $c "$namespace" "$version" "$values_file"
            done
            # Добавляем проверку после установки всех чартов
            if [ "$action" = "install" ] || [ "$action" = "upgrade" ]; then
                echo -e "\n${CYAN}Проверка работоспособности сервисов...${NC}"
                "${REPO_ROOT}/tools/connectivity-check/check-services.sh"
            fi
        else
            install_chart $action $chart "$namespace" "$version" "$values_file"
            # Проверяем сервисы после установки критических чартов
            if [ "$action" = "install" ] || [ "$action" = "upgrade" ]; then
                if [ "$chart" = "ollama" ] || [ "$chart" = "open-webui" ]; then
                    echo -e "\n${CYAN}Проверка работоспособности сервиса $chart...${NC}"
                    "${REPO_ROOT}/tools/connectivity-check/check-services.sh"
                fi
            fi
        fi
        ;;
    list)
        echo -e "${CYAN}Установленные чарты в namespace ${namespace:-$NAMESPACE_PROD}:${NC}"
        helm list -n ${namespace:-$NAMESPACE_PROD}
        ;;
    dashboard-token)
        "${SCRIPT_DIR}/get-dashboard-token"
        ;;
    *)
        echo -e "${RED}Ошибка: Неизвестное действие ${action}${NC}"
        usage
        ;;
esac