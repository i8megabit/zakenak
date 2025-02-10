#!/bin/bash

echo "Checking services connectivity..."

# Проверка DNS резолвинга
echo "Checking DNS resolution..."
echo "ollama.local resolves to:"
getent hosts ollama.local || echo "Failed to resolve ollama.local"

# Проверка портов
echo -e "\nChecking ports..."
nc -zv localhost 80 2>&1
nc -zv ollama.local 80 2>&1

# Проверка HTTP доступности
echo -e "\nChecking HTTP accessibility..."
curl -I http://localhost/open-webui
curl -I http://ollama.local

# Проверка статуса подов
echo -e "\nChecking Kubernetes pods status..."
kubectl get pods -A | grep -E 'ollama|webui'

# Проверка Ingress
echo -e "\nChecking Ingress configuration..."
kubectl get ingress -A