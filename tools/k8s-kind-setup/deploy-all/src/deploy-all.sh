#!/usr/bin/bash
# Загрузка переменных окружения и баннеров
export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export TOOLS_DIR="${BASE_DIR}/tools/k8s-kind-setup"
export SCRIPTS_ENV_PATH="${TOOLS_DIR}/env/src/env.sh"

# Функция вывода справки
show_help() {
    echo "Использование: $0 [--no-wsl] [--help]"
    echo ""
    echo "Опции:"
    echo "  --no-wsl        Пропустить настройку WSL"
    echo "  --help          Показать эту справку"
    echo ""
    exit 0
}


# Парсинг аргументов командной строки
SKIP_WSL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-wsl)
            SKIP_WSL=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Неизвестный параметр: $1"
            show_help
            exit 1
            ;;
    esac
done



source "${SCRIPTS_ENV_PATH}"
source "${SCRIPTS_ASCII_BANNERS_PATH}"

show_deploy_banner

# Функция для логирования
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Функция для установки прав выполнения
setup_executable_permissions() {
    local scripts=(
        "${SCRIPTS_ENV_PATH}"
        "${SCRIPTS_ASCII_BANNERS_PATH}"
        "${SCRIPTS_SETUP_WSL_PATH}"
        "${SCRIPTS_SETUP_BINS_PATH}"
        "${SCRIPTS_SETUP_KIND_PATH}"
        "${SCRIPTS_SETUP_INGRESS_PATH}"
        "${SCRIPTS_SETUP_CERT_MANAGER_PATH}"
        "${SCRIPTS_SETUP_DNS_PATH}"
        "${SCRIPTS_DASHBOARD_TOKEN_PATH}"
        "${SCRIPTS_CHARTS_PATH}"
        "${SCRIPTS_CONNECTIVITY_CHECK_PATH}"
    )

    echo "Установка прав выполнения для скриптов..."
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            chmod +x "$script"
        else
            echo "Предупреждение: Файл $script не найден"
        fi
    done
}

# Установка прав выполнения
setup_executable_permissions

# Функция проверки наличия необходимых утилит
check_dependencies() {
    local required_tools=("docker" "kind" "kubectl" "helm" "curl" "nc" "getent")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo "Ошибка: Утилита $tool не установлена"
            exit 1
        fi
    done
}

# Проверка наличия необходимых файлов конфигурации
required_files=(
    "${SCRIPTS_ENV_PATH}"
    "${SCRIPTS_ASCII_BANNERS_PATH}"
    "${SCRIPTS_SETUP_WSL_PATH}"
    "${SCRIPTS_SETUP_BINS_PATH}"
    "${SCRIPTS_SETUP_KIND_PATH}"
    "${SCRIPTS_SETUP_INGRESS_PATH}"
    "${SCRIPTS_SETUP_CERT_MANAGER_PATH}"
    "${SCRIPTS_SETUP_DNS_PATH}"
    "${SCRIPTS_DASHBOARD_TOKEN_PATH}"
    "${SCRIPTS_CHARTS_PATH}"
    "${SCRIPTS_CONNECTIVITY_CHECK_PATH}"
)

# Проверка существования всех необходимых файлов
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Ошибка: Не найден требуемый файл: $file"
        exit 1
    fi
done

# Последовательное выполнение всех этапов установки
log "Начало полного развертывания кластера..."

# Настройка WSL
if [ "$SKIP_WSL" = false ]; then
    log "Настройка WSL окружения..."
    source "${SCRIPTS_SETUP_WSL_PATH}"
    
    # Добавляем настройку GPU
    log "Настройка GPU в WSL..."
    if ! source "${SCRIPTS_SETUP_WSL_GPU_PATH}"; then
        log "Предупреждение: Ошибка при настройке GPU в WSL"
        # Продолжаем выполнение, так как GPU может быть необязательным
    fi
else
    log "Пропуск настройки WSL (--no-wsl)"
fi

# Установка бинарных компонентов
log "Установка необходимых компонентов..."
source "${SCRIPTS_SETUP_BINS_PATH}"

# Проверка зависимостей после установки компонентов
log "Проверка установленных компонентов..."
check_dependencies

# Развертывание Kind кластера
log "Развертывание Kind кластера..."
if ! source "${SCRIPTS_SETUP_KIND_PATH}"; then
    log "Ошибка при развертывании Kind кластера"
    exit 1
fi

# Настройка Ingress Controller
log "Настройка Ingress Controller..."
if ! source "${SCRIPTS_SETUP_INGRESS_PATH}"; then
    log "Ошибка при настройке Ingress Controller"
    exit 1
fi

# Установка Cert Manager
log "Установка Cert Manager..."
if ! source "${SCRIPTS_SETUP_CERT_MANAGER_PATH}"; then
    log "Ошибка при установке Cert Manager"
    exit 1
fi

# Настройка DNS
log "Настройка DNS..."
if ! source "${SCRIPTS_SETUP_DNS_PATH}"; then
    log "Ошибка при настройке DNS"
    exit 1
fi

# Получение токена для Dashboard
log "Генерация токена для Dashboard..."
if ! source "${SCRIPTS_DASHBOARD_TOKEN_PATH}"; then
    log "Ошибка при генерации токена для Dashboard"
    exit 1
fi

# Установка Helm чартов
log "Установка Helm чартов..."
if ! source "${SCRIPTS_CHARTS_PATH}"; then
    log "Ошибка при установке Helm чартов"
    exit 1
fi




# Проверка доступности сервисов
log "Проверка доступности сервисов..."
if ! source "${SCRIPTS_CONNECTIVITY_CHECK_PATH}"; then
    log "Ошибка при проверке доступности сервисов"
    exit 1
fi

log "Развертывание успешно завершено!"