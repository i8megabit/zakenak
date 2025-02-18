#!/bin/bash

# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# Script for generating Kubernetes cluster configuration

set -e

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Получение данных из текущего контекста
CURRENT_CONTEXT=$(kubectl config current-context)
CLUSTER_NAME="kind-zakenak"
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CA_DATA=$(kubectl config view --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
CLIENT_CERT_DATA=$(kubectl config view --minify --flatten -o jsonpath='{.users[0].user.client-certificate-data}')
CLIENT_KEY_DATA=$(kubectl config view --minify --flatten -o jsonpath='{.users[0].user.client-key-data}')

# Создание конфигурации из шаблона
sed -e "s/\${CA_DATA}/${CA_DATA}/g" \
	-e "s/\${CLIENT_CERT_DATA}/${CLIENT_CERT_DATA}/g" \
	-e "s/\${CLIENT_KEY_DATA}/${CLIENT_KEY_DATA}/g" \
	"${REPO_ROOT}/kubeconfig.yaml" > "${REPO_ROOT}/kubeconfig.generated.yaml"

echo "Конфигурация кластера успешно создана в kubeconfig.generated.yaml"
echo "Теперь вы можете использовать её для доступа к кластеру:"
echo "export KUBECONFIG=${REPO_ROOT}/kubeconfig.generated.yaml"