#!/bin/bash
set -euo pipefail

echo "Starting Kubernetes installation in WSL2..."

# Проверка WSL2
if ! grep -q microsoft /proc/version; then
	echo "This script must be run in WSL2"
	exit 1
fi

# Настройка WSL2
echo "Configuring WSL2..."
cat << EOF > "${HOME}/.wslconfig"
[wsl2]
memory=16GB
processors=4
swap=8GB
localhostForwarding=true
kernelCommandLine=systemd=true
EOF

# Установка базовых зависимостей
echo "Installing dependencies..."
sudo apt-get update && sudo apt-get install -y \
	apt-transport-https \
	ca-certificates \
	curl \
	software-properties-common \
	gnupg \
	make

# Установка CUDA
echo "Installing CUDA..."
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin
sudo mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda-repo-wsl-ubuntu-12-8-local_12.8.0-1_amd64.deb
sudo dpkg -i cuda-repo-wsl-ubuntu-12-8-local_12.8.0-1_amd64.deb
sudo cp /var/cuda-repo-wsl-ubuntu-12-8-local/cuda-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-8

# Установка Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Настройка NVIDIA Container Toolkit
echo "Setting up NVIDIA Container Toolkit..."
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Установка kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Установка Helm
echo "Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Установка Kind
echo "Installing Kind..."
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Создание конфигурации Kind кластера
echo "Creating Kind cluster configuration..."
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

# Создание Kind кластера
echo "Creating Kind cluster..."
kind create cluster --config kind-config.yaml

# Установка NVIDIA Device Plugin
echo "Installing NVIDIA Device Plugin..."
kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.1/nvidia-device-plugin.yml

# Установка Cert Manager
echo "Installing Cert Manager..."
helm upgrade --install \
	cert-manager ./helm-charts/cert-manager \
	--namespace prod \
	--create-namespace \
	--set installCRDs=true \
	--values ./helm-charts/cert-manager/values.yaml

# Установка Local CA
echo "Installing Local CA..."
helm upgrade --install \
	local-ca ./helm-charts/local-ca \
	--namespace prod \
	--values ./helm-charts/local-ca/values.yaml

# Установка Sidecar Injector
echo "Installing Sidecar Injector..."
helm upgrade --install \
	sidecar-injector ./helm-charts/sidecar-injector \
	--namespace prod \
	--values ./helm-charts/sidecar-injector/values.yaml

# Проверка установки
echo "Verifying installation..."
kubectl cluster-info
kubectl get nodes
nvidia-smi

echo "Kubernetes installation complete!"