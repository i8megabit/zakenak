#!/usr/bin/bash

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Добавление пути репозитория в PATH
export PATH="${REPO_ROOT}/tools/k8s-kind-setup:${REPO_ROOT}/tools/helm-setup:${REPO_ROOT}/tools/helm-deployer:${PATH}"

# Создание кластера Kind
echo "Creating Kind cluster..."
kind create cluster

# Установка Ingress Controller
echo "Setting up Ingress Controller..."
chmod +x "${SCRIPT_DIR}/setup-ingress"
"${SCRIPT_DIR}/setup-ingress"

echo "Setup completed successfully!"