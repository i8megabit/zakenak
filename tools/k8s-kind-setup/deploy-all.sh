#!/usr/bin/bash

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Добавление пути репозитория в PATH
export PATH="${REPO_ROOT}/tools/k8s-kind-setup:${REPO_ROOT}/tools/helm-setup:${REPO_ROOT}/tools/helm-deployer:${PATH}"

# Загрузка общих переменных и функций
source "${SCRIPT_DIR}/env"

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

# 1. Пересоздание кластера Kind
recreate_cluster

# 2. Установка Ingress Controller
echo -e "${CYAN}Установка Ingress Controller...${NC}"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install $RELEASE_INGRESS ingress-nginx/ingress-nginx \
	--namespace $NAMESPACE_INGRESS \
	--create-namespace \
	--version $NGINX_INGRESS_VERSION \
	--set controller.service.type=NodePort \
	--set controller.hostPort.enabled=true \
	--wait
check_error "Не удалось установить Ingress Controller"

# 3. Установка cert-manager
echo -e "${CYAN}Установка cert-manager...${NC}"
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Создание namespace
kubectl create namespace $NAMESPACE_PROD --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $NAMESPACE_CERT_MANAGER --dry-run=client -o yaml | kubectl apply -f -

# Установка cert-manager
helm upgrade --install $RELEASE_CERT_MANAGER jetstack/cert-manager \
	--namespace $NAMESPACE_CERT_MANAGER \
	--version $CERT_MANAGER_VERSION \
	--set installCRDs=true \
	--wait
check_error "Не удалось установить cert-manager"

# Ожидание готовности CRDs и подов
wait_for_crds "certificates.cert-manager.io" "clusterissuers.cert-manager.io" "issuers.cert-manager.io"
wait_for_pods $NAMESPACE_CERT_MANAGER "app.kubernetes.io/instance=cert-manager"

# 4. Установка Local CA
echo -e "${CYAN}Установка Local CA...${NC}"
helm upgrade --install $RELEASE_LOCAL_CA "${CHART_PATH_LOCAL_CA}" \
	--namespace $NAMESPACE_PROD \
	--wait
check_error "Не удалось установить Local CA"

# 5. Настройка CoreDNS
echo -e "${CYAN}Настройка CoreDNS...${NC}"
kubectl apply -f "${SCRIPT_DIR}/manifests/coredns-custom-config.yaml"
kubectl apply -f "${SCRIPT_DIR}/manifests/coredns-patch.yaml"
kubectl rollout restart deployment coredns -n kube-system
check_error "Не удалось настроить CoreDNS"

# 6. Установка Ollama
echo -e "${CYAN}Установка Ollama...${NC}"
helm upgrade --install $RELEASE_OLLAMA "${CHART_PATH_OLLAMA}" \
	--namespace $NAMESPACE_PROD \
	--wait
check_error "Не удалось установить Ollama"

# 7. Установка Open WebUI
echo -e "${CYAN}Установка Open WebUI...${NC}"
helm upgrade --install $RELEASE_WEBUI "${CHART_PATH_WEBUI}" \
	--namespace $NAMESPACE_PROD \
	--wait
check_error "Не удалось установить Open WebUI"

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

