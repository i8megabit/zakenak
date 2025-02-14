#!/bin/bash

# Цвета для вывода
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Функция проверки ошибок
check_error() {
	if [ $? -ne 0 ]; then
		echo -e "${RED}Ошибка: $1${NC}"
		exit 1
	fi
}

# Функция ожидания готовности подов
wait_for_pods() {
	namespace=$1
	label=$2
	echo -e "${CYAN}Ожидание готовности подов в namespace $namespace с меткой $label...${NC}"
	kubectl wait --for=condition=Ready pods -l $label -n $namespace --timeout=300s
	check_error "Поды не готовы в namespace $namespace"
}

echo -e "${YELLOW}Начинаем развертывание компонентов...${NC}"

# 1. Создание кластера Kind с поддержкой Ingress
echo -e "${CYAN}Создание кластера Kind...${NC}"
kind create cluster --config kind-config.yaml
check_error "Не удалось создать кластер Kind"

# 2. Установка Ingress Controller
echo -e "${CYAN}Установка Ingress Controller...${NC}"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
	--namespace ingress-nginx \
	--create-namespace \
	--set controller.service.type=NodePort \
	--set controller.hostPort.enabled=true \
	--wait
check_error "Не удалось установить Ingress Controller"

# 3. Установка cert-manager
echo -e "${CYAN}Установка cert-manager...${NC}"
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install cert-manager jetstack/cert-manager \
	--namespace prod \
	--set installCRDs=true \
	--wait
check_error "Не удалось установить cert-manager"

# 4. Настройка CoreDNS
echo -e "${CYAN}Настройка CoreDNS...${NC}"
kubectl apply -f ./manifests/coredns-custom-config.yaml
kubectl apply -f ./manifests/coredns-patch.yaml
kubectl rollout restart deployment coredns -n kube-system
check_error "Не удалось настроить CoreDNS"

# 5. Установка NVIDIA device plugin
echo -e "${CYAN}Установка NVIDIA device plugin...${NC}"
kubectl apply -f ../helm-charts/ollama/templates/nvidia-device-plugin.yaml
check_error "Не удалось установить NVIDIA device plugin"

# 6. Добавление метки GPU для Ollama
echo -e "${CYAN}Добавление метки GPU для узлов...${NC}"
kubectl label nodes --all nvidia.com/gpu=present --overwrite
check_error "Не удалось добавить метку GPU"

# 7. Установка Ollama
echo -e "${CYAN}Установка Ollama...${NC}"
helm upgrade --install ollama ../helm-charts/ollama \
	--namespace prod \
	--values ../helm-charts/ollama/values.yaml \
	--wait
check_error "Не удалось установить Ollama"

# 8. Установка Open WebUI
echo -e "${CYAN}Установка Open WebUI...${NC}"
helm upgrade --install open-webui ../helm-charts/open-webui \
	--namespace prod \
	--values ../helm-charts/open-webui/values.yaml \
	--wait
check_error "Не удалось установить Open WebUI"

# Проверка статуса развертывания
echo -e "${CYAN}Проверка статуса всех компонентов...${NC}"
kubectl get pods -n prod
kubectl get pods -n ingress-nginx
kubectl get ingress -n prod

echo -e "${GREEN}Развертывание успешно завершено!${NC}"
echo -e "${YELLOW}Для проверки доступности сервисов:${NC}"
echo -e "1. Ollama API: https://ollama.prod.local"
echo -e "2. Open WebUI: https://webui.prod.local"