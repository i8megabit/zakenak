#!/bin/bash

# Функция для установки KIND если он не установлен
install_kind() {
	if ! command -v kind &> /dev/null; then
		echo "Установка KIND..."
		curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
		chmod +x ./kind
		sudo mv ./kind /usr/local/bin/
	fi
}

# Функция для установки kubectl если он не установлен
install_kubectl() {
	if ! command -v kubectl &> /dev/null; then
		echo "Установка kubectl..."
		curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
		chmod +x kubectl
		sudo mv kubectl /usr/local/bin/
	fi
}

# Функция для установки Helm если он не установлен
install_helm() {
	if ! command -v helm &> /dev/null; then
		echo "Установка Helm..."
		curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
		chmod +x get_helm.sh
		./get_helm.sh
		rm get_helm.sh
	fi
}

# Установка всех компонентов
install_kind
install_kubectl
install_helm

echo "Установка бинарных компонентов завершена."