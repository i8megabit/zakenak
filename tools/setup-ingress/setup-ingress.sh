#!/bin/bash

set -euo pipefail

# Определение цветов для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Конфигурационные переменные
INGRESS_NAMESPACE=${INGRESS_NAMESPACE:-"ingress-nginx"}
INGRESS_CLASS_NAME=${INGRESS_CLASS_NAME:-"nginx"}
ENABLE_TLS=${ENABLE_TLS:-"true"}
CHART_VERSION="4.8.3"

echo -e "${GREEN}Начинаем установку NGINX Ingress Controller...${NC}"

# Создание namespace если он не существует
if ! kubectl get namespace "$INGRESS_NAMESPACE" >/dev/null 2>&1; then
	echo "Создание namespace $INGRESS_NAMESPACE..."
	kubectl create namespace "$INGRESS_NAMESPACE"
fi

# Добавление helm репозитория
echo "Добавление helm репозитория ingress-nginx..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Подготовка values для helm
VALUES_FILE=$(mktemp)
cat << EOF > "$VALUES_FILE"
controller:
  ingressClassResource:
	name: ${INGRESS_CLASS_NAME}
	enabled: true
	default: true
  service:
	type: NodePort
  admissionWebhooks:
	enabled: true
EOF

# Установка ingress-controller
echo "Установка NGINX Ingress Controller..."
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
	--namespace "$INGRESS_NAMESPACE" \
	--version "$CHART_VERSION" \
	-f "$VALUES_FILE"

# Очистка временного файла
rm -f "$VALUES_FILE"

# Проверка установки
echo "Ожидание запуска ingress-controller..."
kubectl wait --namespace "$INGRESS_NAMESPACE" \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

echo -e "${GREEN}NGINX Ingress Controller успешно установлен!${NC}"

# Вывод информации о созданных ресурсах
echo -e "\nСозданные ресурсы:"
kubectl get all -n "$INGRESS_NAMESPACE"