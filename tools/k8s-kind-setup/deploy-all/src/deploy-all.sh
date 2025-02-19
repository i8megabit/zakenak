#!/usr/bin/bash
#  ____             _             
# |  _ \  ___ _ __ | | ___  _   _ 
# | | | |/ _ \ '_ \| |/ _ \| | | |
# | |_| |  __/ |_) | | (_) | |_| |
# |____/ \___| .__/|_|\___/ \__, |
#            |_|            |___/ 
#                         by @eberil
#
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# This code is free! Share it, spread peace and technology!
# "Time to ship some containers!"

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Загрузка переменных окружения и баннеров
source "${SCRIPT_DIR}/env/src/env.sh"
source "${SCRIPT_DIR}/ascii-banners/src/ascii_banners.sh"
show_deploy_banner

# Функция для логирования
log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Установка бинарных компонентов
log "Установка необходимых компонентов..."
source "${SCRIPT_DIR}/setup-bins/src/setup-bins.sh"

# Проверка наличия необходимых утилит

check_dependencies() {
	local required_tools=("docker" "kind" "kubectl" "helm" "curl" "nc" "getent")
	for tool in "${required_tools[@]}"; do
		if ! command -v "$tool" &> /dev/null; then
			echo "Ошибка: Утилита $tool не установлена"
			exit 1
		fi
	done
}

# Выполняем проверку зависимостей
check_dependencies

# Проверка наличия необходимых файлов конфигурации
required_files=(
	"${SCRIPT_DIR}/env/src/env.sh"
	"${SCRIPT_DIR}/ascii-banners/src/ascii_banners.sh"
	"${SCRIPT_DIR}/setup-wsl/src/setup-wsl.sh"
	"${SCRIPT_DIR}/setup-bins/src/setup-bins.sh"
	"${SCRIPT_DIR}/setup-kind/src/setup-kind.sh"
	"${SCRIPT_DIR}/setup-ingress/src/setup-ingress.sh"
	"${SCRIPT_DIR}/setup-cert-manager/src/setup-cert-manager.sh"
	"${SCRIPT_DIR}/setup-dns/src/setup-dns.sh"
	"${SCRIPT_DIR}/dashboard-token/src/dashboard-token.sh"
	"${SCRIPT_DIR}/charts/src/charts.sh"
	"${SCRIPT_DIR}/connectivity-check/src/check-services.sh"
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
source "${SCRIPT_DIR}/setup-wsl/src/setup-wsl.sh"

# Установка бинарных компонентов
log "Установка необходимых компонентов..."
source "${SCRIPT_DIR}/setup-bins/src/setup-bins.sh"

# Развертывание Kind кластера
log "Развертывание Kind кластера..."
source "${SCRIPT_DIR}/setup-kind/src/setup-kind.sh"

# Настройка Ingress Controller
log "Настройка Ingress Controller..."
source "${SCRIPT_DIR}/setup-ingress/src/setup-ingress.sh"

# Установка Cert Manager
log "Установка Cert Manager..."
source "${SCRIPT_DIR}/setup-cert-manager/src/setup-cert-manager.sh"

# Настройка DNS
log "Настройка DNS..."
source "${SCRIPT_DIR}/setup-dns/src/setup-dns.sh"

# Получение токена для Dashboard
log "Генерация токена для Dashboard..."
source "${SCRIPT_DIR}/dashboard-token/src/dashboard-token.sh"

# Установка Helm чартов
log "Установка Helm чартов..."
source "${SCRIPT_DIR}/charts/src/charts.sh"

# Проверка доступности сервисов
log "Проверка доступности сервисов..."
source "${SCRIPT_DIR}/connectivity-check/src/check-services.sh"

log "Развертывание успешно завершено!"