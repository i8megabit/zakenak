#!/usr/bin/bash
# Определение пути к директории скрипта и корню проекта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Загрузка переменных окружения и баннеров
source "${SCRIPT_DIR}/env/src/env.sh"
source "$SCRIPTS_ASCII_BANNERS_PATH"

show_deploy_banner

# Функция для логирования
log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Функция для установки прав выполнения
setup_executable_permissions() {
	local scripts=(
		"$SCRIPTS_ENV_PATH"
		"$SCRIPTS_ASCII_BANNERS_PATH"
		"$SCRIPTS_SETUP_WSL_PATH"
		"$SCRIPTS_SETUP_BINS_PATH"
		"$SCRIPTS_SETUP_KIND_PATH"
		"$SCRIPTS_SETUP_INGRESS_PATH"
		"$SCRIPTS_SETUP_CERT_MANAGER_PATH"
		"$SCRIPTS_SETUP_DNS_PATH"
		"$SCRIPTS_DASHBOARD_TOKEN_PATH"
		"$SCRIPTS_CHARTS_PATH"
		"$SCRIPTS_CONNECTIVITY_CHECK_PATH"
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

# Установка бинарных компонентов
log "Установка необходимых компонентов..."
source "${SCRIPT_DIR}/setup-bins/src/setup-bins.sh"

# Проверка наличия необходимых утилит после установки
check_dependencies() {
	local required_tools=("docker" "kind" "kubectl" "helm" "curl" "nc" "getent")
	for tool in "${required_tools[@]}"; do
		if ! command -v "$tool" &> /dev/null; then
			echo "Ошибка: Утилита $tool не установлена"
			exit 1
		fi
	done
}

# Выполняем проверку зависимостей после установки
check_dependencies


# Проверка наличия необходимых файлов конфигурации
required_files=(
	"$SCRIPTS_ENV_PATH"
	"$SCRIPTS_ASCII_BANNERS_PATH"
	"$SCRIPTS_SETUP_WSL_PATH"
	"$SCRIPTS_SETUP_BINS_PATH"
	"$SCRIPTS_SETUP_KIND_PATH"
	"$SCRIPTS_SETUP_INGRESS_PATH"
	"$SCRIPTS_SETUP_CERT_MANAGER_PATH"
	"$SCRIPTS_SETUP_DNS_PATH"
	"$SCRIPTS_DASHBOARD_TOKEN_PATH"
	"$SCRIPTS_CHARTS_PATH"
	"$SCRIPTS_CONNECTIVITY_CHECK_PATH"
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
log "Настройка WSL окружения..."
source "$SCRIPTS_SETUP_WSL_PATH"

# Установка бинарных компонентов
log "Установка необходимых компонентов..."
source "$SCRIPTS_SETUP_BINS_PATH"

# Развертывание Kind кластера
log "Развертывание Kind кластера..."
source "$SCRIPTS_SETUP_KIND_PATH"

# Настройка Ingress Controller
log "Настройка Ingress Controller..."
source "$SCRIPTS_SETUP_INGRESS_PATH"

# Установка Cert Manager
log "Установка Cert Manager..."
source "$SCRIPTS_SETUP_CERT_MANAGER_PATH"

# Настройка DNS
log "Настройка DNS..."
source "$SCRIPTS_SETUP_DNS_PATH"

# Получение токена для Dashboard
log "Генерация токена для Dashboard..."
source "$SCRIPTS_DASHBOARD_TOKEN_PATH"

# Установка Helm чартов
log "Установка Helm чартов..."
source "$SCRIPTS_CHARTS_PATH"

# Проверка доступности сервисов
log "Проверка доступности сервисов..."
source "$SCRIPTS_CONNECTIVITY_CHECK_PATH"

log "Развертывание успешно завершено!"