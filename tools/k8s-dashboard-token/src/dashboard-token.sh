#!/bin/bash
#
# Kubernetes Dashboard Token Generator
# Version: 1.0.0
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# This code is free! Share it, spread peace and technology!

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Загрузка общих компонентов
source "${REPO_ROOT}/tools/k8s-kind-setup/env"
source "${REPO_ROOT}/tools/k8s-kind-setup/ascii-banners/src/ascii_banners.sh"

# Отображение баннера при старте
dashboard_banner
echo ""

# Константы
NAMESPACE="kubernetes-dashboard"
SA_NAME="admin-user"

# Функция для проверки наличия необходимых компонентов
check_prerequisites() {
	if ! command -v kubectl &> /dev/null; then
		echo "❌ kubectl не установлен"
		exit 1
	fi
	
	if ! kubectl cluster-info &> /dev/null; then
		echo "❌ Нет доступа к кластеру Kubernetes"
		exit 1
	fi
}

# Функция для определения версии Kubernetes
get_k8s_version() {
	local version
	version=$(kubectl version --short 2>/dev/null | grep "Server Version" | cut -d " " -f3 | cut -d "." -f2)
	echo "$version"
}

# Функция для получения токена в зависимости от версии K8s
get_dashboard_token() {
	local k8s_version
	k8s_version=$(get_k8s_version)
	
	if [ "$k8s_version" -ge "24" ]; then
		# Для версий K8s >= 1.24
		kubectl create token "$SA_NAME" -n "$NAMESPACE"
	else
		# Для версий K8s < 1.24
		kubectl -n "$NAMESPACE" describe secret "$(kubectl -n "$NAMESPACE" get secret | grep "$SA_NAME" | awk '{print $1}')" | grep "token:" | awk '{print $2}'
	fi
}

# Основная логика
main() {
	echo "🔍 Проверка необходимых компонентов..."
	check_prerequisites
	
	echo "🔑 Генерация токена для Kubernetes Dashboard..."
	TOKEN=$(get_dashboard_token)
	
	if [ -n "$TOKEN" ]; then
		echo "✅ Токен успешно получен:"
		echo "$TOKEN"
		echo ""
		echo "📝 Инструкции по использованию:"
		echo "1. Запустите: kubectl proxy"
		echo "2. Откройте: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
		echo "3. Используйте полученный токен для входа"
	else
		echo "❌ Не удалось получить токен"
		exit 1
	fi
}

# Запуск скрипта
main