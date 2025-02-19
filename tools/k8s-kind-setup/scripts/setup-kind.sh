#!/bin/bash
set -euo pipefail

# Глобальные переменные
KIND_VERSION="v0.20.0"
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
HELM_VERSION="v3.13.3"

# Функции логирования
log_info() {
	echo "[INFO] $1"
}

log_error() {
	echo "[ERROR] $1" >&2
}

# Установка kubectl
install_kubectl() {
	log_info "Установка kubectl ${KUBECTL_VERSION}..."
	curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
	sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
}

# Установка Helm
install_helm() {
	log_info "Установка Helm ${HELM_VERSION}..."
	curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
}

# Установка Kind
install_kind() {
	log_info "Установка Kind ${KIND_VERSION}..."
	curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64
	chmod +x ./kind
	sudo mv ./kind /usr/local/bin/kind
}

# Создание конфигурации Kind кластера
create_kind_config() {
	log_info "Создание конфигурации Kind кластера..."
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
		node-labels: "ingress-ready=true,nvidia.com/gpu=present"
  extraMounts:
  - hostPath: /usr/lib/wsl/lib
	containerPath: /usr/lib/wsl/lib
  - hostPath: /usr/local/cuda-12.8
	containerPath: /usr/local/cuda-12.8
  - hostPath: /usr/local/cuda
	containerPath: /usr/local/cuda
  extraPortMappings:
  - containerPort: 80
	hostPort: 80
  - containerPort: 443
	hostPort: 443
EOF
}

# Создание кластера
create_cluster() {
	log_info "Создание Kind кластера..."
	kind create cluster --config kind-config.yaml
}

# Установка NVIDIA Device Plugin
install_nvidia_plugin() {
	log_info "Установка NVIDIA Device Plugin..."
	kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.1/nvidia-device-plugin.yml
}

# Установка базовых сервисов
install_base_services() {
	log_info "Установка базовых сервисов..."
	
	# Cert Manager
	helm upgrade --install \
		cert-manager ./helm-charts/cert-manager \
		--namespace prod \
		--create-namespace \
		--set installCRDs=true \
		--values ./helm-charts/cert-manager/values.yaml

	# Local CA
	helm upgrade --install \
		local-ca ./helm-charts/local-ca \
		--namespace prod \
		--values ./helm-charts/local-ca/values.yaml

	# Sidecar Injector
	helm upgrade --install \
		sidecar-injector ./helm-charts/sidecar-injector \
		--namespace prod \
		--values ./helm-charts/sidecar-injector/values.yaml
}

# Проверка установки
verify_cluster() {
	log_info "Проверка кластера..."
	kubectl cluster-info
	kubectl get nodes
	kubectl get pods -A
}

# Основная функция
main() {
	log_info "Начало установки Kind кластера..."
	
	install_kubectl
	install_helm
	install_kind
	create_kind_config
	create_cluster
	install_nvidia_plugin
	install_base_services
	verify_cluster
	
	log_info "Установка Kind кластера завершена успешно!"
}

main "$@"