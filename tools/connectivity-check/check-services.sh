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
nc -zv ollama.prod.local 80 2>&1
nc -zv webui.prod.local 80 2>&1
nc -zv ollama.prod.local 443 2>&1
nc -zv webui.prod.local 443 2>&1

# Проверка HTTP доступности
echo -e "\nChecking HTTP accessibility..."
curl -I http://webui.prod.local
curl -I http://ollama.prod.local

# Проверка статуса подов
echo -e "\nChecking Kubernetes pods status..."
kubectl get pods -A | grep -E 'ollama|webui'

# Проверка Ingress
echo -e "\nChecking Ingress configuration..."
kubectl get ingress -A