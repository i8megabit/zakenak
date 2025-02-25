#!/bin/bash
set -euo pipefail

# Цветовые коды
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Начало настройки WSL2 для Kubernetes...${NC}"

# Проверка WSL2
if ! grep -q microsoft /proc/version; then
    echo -e "${RED}Этот скрипт должен быть запущен в WSL2${NC}"
    exit 1
fi

# Настройка WSL2
echo "Настройка WSL2..."
cat << EOF > "${HOME}/.wslconfig"
[wsl2]
memory=40GB
processors=12
swap=16GB
localhostForwarding=true
kernelCommandLine=systemd.unified_cgroup_hierarchy=1
nestedVirtualization=true
guiApplications=true
debugConsole=false
[experimental]
hostAddressLoopback=true
bestEffortDnsParsing=true
EOF

# Проверка nvidia-smi
echo "Проверка GPU..."
if ! command -v nvidia-smi &> /dev/null; then
    echo -e "${RED}nvidia-smi не найден. Убедитесь, что:${NC}"
    echo "1. NVIDIA драйвер установлен в Windows (версия 535.104.05 или выше)"
    echo "2. WSL2 правильно настроен для работы с GPU"
    exit 1
fi

# Установка базовых зависимостей
echo "Установка зависимостей..."
sudo apt-get update && sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg \
    make \
    wget

# Установка CUDA
echo "Установка CUDA..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! bash "${SCRIPT_DIR}/cuda.sh"; then
    echo -e "${RED}Ошибка при установке CUDA${NC}"
    exit 1
fi

# Настройка NVIDIA Container Toolkit
echo "Настройка NVIDIA Container Toolkit..."

# Очистка старых файлов
sudo rm -f /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo rm -f /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# Установка GPG ключа и настройка репозитория
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Установка NVIDIA Container Toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Настройка container runtime
echo "Настройка container runtime..."
sudo nvidia-ctk runtime configure --runtime=docker

echo -e "${GREEN}Настройка WSL2 успешно завершена!${NC}"
echo -e "${YELLOW}Для применения изменений выполните:${NC}"
echo "1. wsl --shutdown"
echo "2. Перезапустите Docker Desktop"
echo -e "${YELLOW}Для проверки GPU выполните:${NC}"
echo "nvidia-smi"
echo "docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi"