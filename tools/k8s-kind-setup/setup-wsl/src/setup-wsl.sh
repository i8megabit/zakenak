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

echo "WSL2 setup completed successfully!"
echo "Please restart your WSL instance for changes to take effect."