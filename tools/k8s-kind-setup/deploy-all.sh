#!/bin/bash

# Загрузка общих переменных
source ./env.sh

echo -e "${YELLOW}Начинаем развертывание компонентов...${NC}"

# Функция пересоздания кластера
recreate_cluster() {
	echo -e "${CYAN}Проверка существующего кластера...${NC}"
	if kind get clusters 2>/dev/null | grep -q "^kind$"; then
		echo -e "${YELLOW}Обнаружен существующий кластер 'kind'. Удаляем...${NC}"
		kind delete cluster
		check_error "Не удалось удалить существующий кластер"
		sleep 5
	fi
	
	echo -e "${CYAN}Создание нового кластера Kind...${NC}"
	kind create cluster --config kind-config.yaml
	check_error "Не удалось создать кластер Kind"
	
	# Ожидание готовности узлов
	echo -e "${CYAN}Ожидание готовности узлов кластера...${NC}"
	kubectl wait --for=condition=Ready nodes --all --timeout=300s
	check_error "Узлы кластера не готовы"
}

# 1. Пересоздание кластера Kind
recreate_cluster

# 2. Установка Ingress Controller
echo -e "${CYAN}Установка Ingress Controller...${NC}"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install $RELEASE_INGRESS ingress-nginx/ingress-nginx \
	--namespace $NAMESPACE_INGRESS \
	--create-namespace \
	--set controller.service.type=NodePort \
	--set controller.hostPort.enabled=true \
	--wait
check_error "Не удалось установить Ingress Controller"

# 3. Установка cert-manager
echo -e "${CYAN}Установка cert-manager...${NC}"
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl create namespace $NAMESPACE_PROD --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install $RELEASE_CERT_MANAGER jetstack/cert-manager \
	--namespace $NAMESPACE_CERT_MANAGER \
	--set installCRDs=true \
	--wait
check_error "Не удалось установить cert-manager"

# 4. Настройка CoreDNS
echo -e "${CYAN}Настройка CoreDNS...${NC}"
mkdir -p ./manifests
kubectl apply -f ./manifests/coredns-custom-config.yaml
kubectl apply -f ./manifests/coredns-patch.yaml
kubectl rollout restart deployment coredns -n kube-system
check_error "Не удалось настроить CoreDNS"

# 5. Установка Ollama с поддержкой GPU
echo -e "${CYAN}Установка Ollama...${NC}"
helm upgrade --install $RELEASE_OLLAMA $CHART_PATH_OLLAMA \
	--namespace $NAMESPACE_PROD \
	--create-namespace \
	--values $CHART_PATH_OLLAMA/values.yaml \
	--wait
check_error "Не удалось установить Ollama"

# 6. Установка Open WebUI
echo -e "${CYAN}Установка Open WebUI...${NC}"
helm upgrade --install $RELEASE_WEBUI $CHART_PATH_WEBUI \
	--namespace $NAMESPACE_PROD \
	--values $CHART_PATH_WEBUI/values.yaml \
	--wait
check_error "Не удалось установить Open WebUI"

# Проверка статуса развертывания
echo -e "${CYAN}Проверка статуса всех компонентов...${NC}"
kubectl get pods -n $NAMESPACE_PROD
kubectl get pods -n $NAMESPACE_INGRESS
kubectl get ingress -n $NAMESPACE_PROD

echo -e "${GREEN}Развертывание успешно завершено!${NC}"
echo -e "${YELLOW}Для проверки доступности сервисов:${NC}"
echo -e "1. Ollama API: https://$OLLAMA_HOST"
echo -e "2. Open WebUI: https://$WEBUI_HOST"
