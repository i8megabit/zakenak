#!/bin/bash

# Создание кластера Kind
echo "Creating Kind cluster..."
kind create cluster

# Установка Ingress Controller
echo "Setting up Ingress Controller..."
chmod +x ./setup-ingress.sh
./setup-ingress.sh

echo "Setup completed successfully!"