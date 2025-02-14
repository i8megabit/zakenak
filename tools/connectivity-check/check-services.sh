#!/bin/bash

echo "Checking services connectivity..."

# Проверка DNS резолвинга
echo "Checking DNS resolution..."
echo "ollama.prod.local resolves to:"
getent hosts ollama.prod.local || echo "Failed to resolve ollama.prod.local"
echo "webui.prod.local resolves to:"
getent hosts webui.prod.local || echo "Failed to resolve webui.prod.local"

# Проверка портов
echo -e "\nChecking ports..."
nc -zv localhost 80 2>&1
nc -zv localhost 443 2>&1
nc -zv ollama.prod.local 443 2>&1
nc -zv webui.prod.local 443 2>&1

# Проверка HTTPS доступности
echo -e "\nChecking HTTPS accessibility..."
curl -k -I https://webui.prod.local
curl -k -I https://ollama.prod.local

# Проверка статуса подов
echo -e "\nChecking Kubernetes pods status..."
kubectl get pods -A | grep -E 'ollama|webui|cert-manager|ingress'

# Проверка сертификатов
echo -e "\nChecking Certificate resources..."
kubectl get certificates -n prod
kubectl get secrets -n prod | grep -E 'ollama-tls|open-webui-tls'

# Проверка Ingress и TLS
echo -e "\nChecking Ingress configuration..."
kubectl get ingress -A
kubectl get certificates -A
kubectl get secrets -n prod | grep tls