#!/bin/bash

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Загрузка общих переменных
source "${SCRIPT_DIR}/env.sh"

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
	kind create cluster --config "${SCRIPT_DIR}/kind-config.yaml"
	check_error "Не удалось создать кластер Kind"
	
	# Ожидание готовности узлов
	echo -e "${CYAN}Ожидание готовности узлов кластера...${NC}"
	kubectl wait --for=condition=Ready nodes --all --timeout=300s
	check_error "Узлы кластера не готовы"
}

# Функция установки чарта
install_chart() {
	local release_name=$1
	local chart_path=$2
	local namespace=$3
	
	echo -e "${CYAN}Установка чарта $release_name...${NC}"
	helm upgrade --install "$release_name" "$chart_path" \
		--namespace "$namespace" \
		--create-namespace \
		--values "$chart_path/values.yaml" \
		--wait
	check_error "Не удалось установить чарт $release_name"
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

# Создание необходимых namespace
kubectl create namespace $NAMESPACE_PROD --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $NAMESPACE_CERT_MANAGER --dry-run=client -o yaml | kubectl apply -f -

# Установка cert-manager с CRDs
helm upgrade --install $RELEASE_CERT_MANAGER jetstack/cert-manager \
	--namespace $NAMESPACE_CERT_MANAGER \
	--set installCRDs=true \
	--wait
check_error "Не удалось установить cert-manager"

# Ожидание готовности CRDs cert-manager
echo -e "${CYAN}Ожидание готовности CRDs cert-manager...${NC}"
kubectl wait --for=condition=Established crd/certificates.cert-manager.io --timeout=60s
kubectl wait --for=condition=Established crd/clusterissuers.cert-manager.io --timeout=60s
kubectl wait --for=condition=Established crd/issuers.cert-manager.io --timeout=60s

# Ожидание готовности подов cert-manager
echo -e "${CYAN}Ожидание готовности подов cert-manager...${NC}"
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=cert-manager -n $NAMESPACE_CERT_MANAGER --timeout=120s

# 4. Установка local-ca
echo -e "${CYAN}Установка Local CA...${NC}"
helm upgrade --install $RELEASE_LOCAL_CA "${REPO_ROOT}/helm-charts/local-ca" \
	--namespace $NAMESPACE_PROD \
	--values "${REPO_ROOT}/helm-charts/local-ca/values.yaml" \
	--wait
check_error "Не удалось установить Local CA"

# 5. Установка sidecar-injector
echo -e "${CYAN}Установка Sidecar Injector...${NC}"
install_chart $RELEASE_SIDECAR_INJECTOR $CHART_PATH_SIDECAR_INJECTOR $NAMESPACE_PROD

# 6. Настройка CoreDNS
echo -e "${CYAN}Настройка CoreDNS...${NC}"
kubectl apply -f "${SCRIPT_DIR}/manifests/coredns-custom-config.yaml"
kubectl apply -f "${SCRIPT_DIR}/manifests/coredns-patch.yaml"
kubectl rollout restart deployment coredns -n kube-system
check_error "Не удалось настроить CoreDNS"

# 7. Установка Ollama с поддержкой GPU
echo -e "${CYAN}Установка Ollama...${NC}"
install_chart $RELEASE_OLLAMA $CHART_PATH_OLLAMA $NAMESPACE_PROD

# 8. Установка Open WebUI
echo -e "${CYAN}Установка Open WebUI...${NC}"
install_chart $RELEASE_WEBUI $CHART_PATH_WEBUI $NAMESPACE_PROD

# Проверка статуса развертывания
echo -e "${CYAN}Проверка статуса всех компонентов...${NC}"
kubectl get pods -n $NAMESPACE_PROD
kubectl get pods -n $NAMESPACE_INGRESS
kubectl get pods -n $NAMESPACE_CERT_MANAGER
kubectl get certificates -n $NAMESPACE_PROD
kubectl get clusterissuers

echo -e "${GREEN}Развертывание успешно завершено!${NC}"
echo -e "${YELLOW}Для проверки доступности сервисов:${NC}"
echo -e "1. Ollama API: https://$OLLAMA_HOST"
echo -e "2. Open WebUI: https://$WEBUI_HOST"
