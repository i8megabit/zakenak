#!/usr/bin/bash
# Загрузка переменных окружения и баннеров
source "/home/eberil/zakenak-1/tools/k8s-kind-setup/env/src/env.sh"
source "/home/eberil/zakenak-1/tools/k8s-kind-setup/ascii-banners/src/ascii_banners.sh"

show_deploy_banner

# Функция для логирования
log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Функция для установки прав выполнения
setup_executable_permissions() {
	local scripts=(
		"/home/eberil/zakenak-1/tools/k8s-kind-setup/env/src/env.sh"
		"/home/eberil/zakenak-1/tools/k8s-kind-setup/ascii-banners/src/ascii_banners.sh"
		"/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-wsl/src/setup-wsl.sh"
		"/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-bins/src/setup-bins.sh"
		"/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-kind/src/setup-kind.sh"
		"/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-ingress/src/setup-ingress.sh"
		"/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-cert-manager/src/setup-cert-manager.sh"
		"/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-dns/src/setup-dns.sh"
		"/home/eberil/zakenak-1/tools/k8s-kind-setup/dashboard-token/src/dashboard-token.sh"
		"/home/eberil/zakenak-1/tools/k8s-kind-setup/charts/src/charts.sh"
		"/home/eberil/zakenak-1/tools/k8s-kind-setup/connectivity-check/src/check-services.sh"
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
	"/home/eberil/zakenak-1/tools/k8s-kind-setup/env/src/env.sh"
	"/home/eberil/zakenak-1/tools/k8s-kind-setup/ascii-banners/src/ascii_banners.sh"
	"/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-wsl/src/setup-wsl.sh"
	"/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-bins/src/setup-bins.sh"
	"/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-kind/src/setup-kind.sh"
	"/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-ingress/src/setup-ingress.sh"
	"/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-cert-manager/src/setup-cert-manager.sh"
	"/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-dns/src/setup-dns.sh"
	"/home/eberil/zakenak-1/tools/k8s-kind-setup/dashboard-token/src/dashboard-token.sh"
	"/home/eberil/zakenak-1/tools/k8s-kind-setup/charts/src/charts.sh"
	"/home/eberil/zakenak-1/tools/k8s-kind-setup/connectivity-check/src/check-services.sh"
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
source "/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-wsl/src/setup-wsl.sh"

# Установка бинарных компонентов
log "Установка необходимых компонентов..."
source "/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-bins/src/setup-bins.sh"

# Проверка зависимостей после установки компонентов
log "Проверка установленных компонентов..."
check_dependencies

# Развертывание Kind кластера
log "Развертывание Kind кластера..."
source "/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-kind/src/setup-kind.sh"

# Настройка Ingress Controller
log "Настройка Ingress Controller..."
source "/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-ingress/src/setup-ingress.sh"

# Установка Cert Manager
log "Установка Cert Manager..."
source "/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-cert-manager/src/setup-cert-manager.sh"

# Настройка DNS
log "Настройка DNS..."
source "/home/eberil/zakenak-1/tools/k8s-kind-setup/setup-dns/src/setup-dns.sh"

# Получение токена для Dashboard
log "Генерация токена для Dashboard..."
source "/home/eberil/zakenak-1/tools/k8s-kind-setup/dashboard-token/src/dashboard-token.sh"

# Установка Helm чартов
log "Установка Helm чартов..."
source "/home/eberil/zakenak-1/tools/k8s-kind-setup/charts/src/charts.sh"

# Проверка доступности сервисов
log "Проверка доступности сервисов..."
source "/home/eberil/zakenak-1/tools/k8s-kind-setup/connectivity-check/src/check-services.sh"

log "Развертывание успешно завершено!"