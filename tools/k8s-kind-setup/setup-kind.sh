#!/bin/bash

# Цвета для вывода
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Функция для проверки наличия команды
check_command() {
 if ! command -v $1 &> /dev/null; then
   echo -e "${RED}Команда $1 не найдена. Устанавливаем...${NC}"
   return 1
 fi
 return 0
}

# Функция для установки Docker
install_docker() {
 if ! check_command docker; then
   sudo apt-get update
   sudo apt-get install -y docker.io
   sudo usermod -aG docker $USER
   sudo service docker start
 fi
}

# Функция для установки kubectl
install_kubectl() {
 if ! check_command kubectl; then
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl
   sudo mv kubectl /usr/local/bin/
 fi
}

# Функция для установки Kind
install_kind() {
 if ! check_command kind; then
   curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
   chmod +x ./kind
   sudo mv ./kind /usr/local/bin/
 fi
}

# Функция для создания конфигурации Kind
create_kind_config() {
 cat << EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
}

# Функция для проверки работоспособности сервисов
check_services() {
    # Проверка kind-кластера
    if ! kind get clusters | grep -q "kind"; then
        echo -e "${RED}Kind кластер не найден. Пересоздаем...${NC}"
        create_kind_config
        kind create cluster --config kind-config.yaml
        sleep 10
    fi
}

# Функция для установки Dashboard
install_dashboard() {
    echo -e "${CYAN}Установка Kubernetes Dashboard...${NC}"
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
    
    # Настройка доступа через NodePort
    kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "nodePort": 30443}]}}'
    
    # Создание админского аккаунта
    cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
}

# Функция для проверки работоспособности кластера
check_cluster() {
 echo -e "${CYAN}Проверка работоспособности кластера...${NC}"
 kubectl get nodes
 kubectl get pods --all-namespaces
}

# Функция для проверки и восстановления CoreDNS
restore_coredns() {
    echo -e "${CYAN}Восстановление конфигурации CoreDNS...${NC}"
    
    # Применение конфигурации CoreDNS
    kubectl apply -f ./manifests/coredns-custom-config.yaml || true
    kubectl apply -f ./manifests/coredns-patch.yaml || true
    
    # Перезапуск CoreDNS
    kubectl rollout restart deployment coredns -n kube-system
    kubectl rollout status deployment coredns -n kube-system --timeout=60s
}

# Функция для проверки и восстановления Ingress
restore_ingress() {
    echo -e "${CYAN}Восстановление Ingress Controller...${NC}"
    
    # Проверка существования namespace
    kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -
    
    # Установка/обновление Ingress контроллера
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --set controller.service.type=NodePort \
        --set controller.hostPort.enabled=true \
        --set controller.service.ports.http=80 \
        --set controller.service.ports.https=443 \
        --wait
}

# Функция для проверки и восстановления cert-manager
restore_cert_manager() {
    echo -e "${CYAN}Восстановление cert-manager...${NC}"
    
    # Проверка существования namespace
    kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
    
    # Добавление репозитория Jetstack
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    
    # Установка/обновление cert-manager
    helm upgrade --install cert-manager jetstack/cert-manager \
        --namespace prod \
        --set installCRDs=true \
        --wait
}

# Функция восстановления
restore_cluster() {
    echo -e "${YELLOW}Начинаем полное восстановление кластера...${NC}"
    
    # Проверка наличия необходимых утилит
    for cmd in kubectl helm kind; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}Ошибка: $cmd не установлен${NC}"
            exit 1
        fi
    done
    
    # Проверка и восстановление сервисов
    check_services
    
    # Ожидание готовности узлов
    echo -e "${CYAN}Ожидание готовности узлов кластера...${NC}"
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    # Восстановление компонентов в правильном порядке
    restore_coredns
    restore_cert_manager
    restore_ingress
    
    # Восстановление Dashboard
    echo -e "${CYAN}Восстановление Kubernetes Dashboard...${NC}"
    kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml 2>/dev/null || true
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
    
    # Настройка доступа через NodePort для Dashboard
    kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "nodePort": 30443}]}}'
    
    # Создание админского аккаунта для Dashboard
    cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
    
    # Проверка состояния всех компонентов
    echo -e "${CYAN}Проверка состояния компонентов...${NC}"
    kubectl get pods --all-namespaces
    
    # Вывод информации о доступе
    echo -e "${GREEN}Восстановление завершено!${NC}"
    echo -e "${YELLOW}Для доступа к Dashboard:${NC}"
    echo -e "1. Выполните: ${CYAN}kubectl proxy${NC}"
    echo -e "2. Откройте в браузере: ${CYAN}https://localhost:30443${NC}"
    
    # Получение токена для входа
    echo -e "${YELLOW}Токен для входа в Dashboard:${NC}"
    kubectl -n kubernetes-dashboard create token admin-user
}

# Основная функция
main() {
    if [ "$1" == "restore" ]; then
        restore_cluster
    else
        echo -e "${YELLOW}Начинаем установку Kubernetes кластера...${NC}"
        install_docker
        install_kubectl
        install_kind
        
        echo -e "${CYAN}Создание Kind кластера...${NC}"
        create_kind_config
        kind create cluster --config kind-config.yaml
        
        install_dashboard
        check_cluster
        
        echo -e "${GREEN}Токен для входа в Dashboard:${NC}"
        kubectl -n kubernetes-dashboard create token admin-user
        
        echo -e "${GREEN}Установка завершена успешно!${NC}"
        echo -e "${YELLOW}Для доступа к Dashboard:${NC}"
        echo -e "1. Выполните: ${CYAN}kubectl proxy${NC}"
        echo -e "2. Откройте в браузере: ${CYAN}https://localhost:30443${NC}"
        echo -e "Или используйте: ${CYAN}http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/${NC}"
    fi
}

# Запуск скрипта
main "$@"