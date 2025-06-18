#!/usr/bin/env bash
set -euo pipefail

# Создаём кластер kind
kind create cluster

# Устанавливаем cert-manager и ждём готовности
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set installCRDs=true --wait

# Ставим чарт local-ca, который зависит от cert-manager
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
helm install test "$SCRIPT_DIR/../helm-charts/local-ca" \
  --namespace test --create-namespace --wait

kubectl get pods -n test

kind delete cluster

