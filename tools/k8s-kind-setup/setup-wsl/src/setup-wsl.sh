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



# Установка Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Настройка NVIDIA Container Toolkit
echo "Setting up NVIDIA Container Toolkit..."

# Очистка старых файлов
sudo rm -f /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo rm -f /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# Установка GPG ключа
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# Добавление стабильного DEB репозитория
curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
	sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
	sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Установка NVIDIA Container Toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

echo "WSL2 setup completed successfully!"
echo "Please restart your WSL instance for changes to take effect."