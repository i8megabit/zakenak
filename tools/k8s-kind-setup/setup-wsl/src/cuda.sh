#!/bin/bash
set -e

# Цветовые коды
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Минимальные версии
MIN_DRIVER_VERSION="535.104.05"
MIN_CUDA_VERSION="12.8"

# Проверка наличия nvidia-smi
check_nvidia_driver() {
    echo -e "${YELLOW}Проверка драйвера NVIDIA...${NC}"
    
    if ! command -v nvidia-smi &> /dev/null; then
        echo -e "${RED}nvidia-smi не найден. Установите драйвер NVIDIA для WSL2${NC}"
        echo "1. Убедитесь, что WSL2 правильно настроен"
        echo "2. Установите драйвер NVIDIA версии $MIN_DRIVER_VERSION или выше"
        return 1
    fi
    
    local driver_version
    driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
    echo -e "Обнаружен драйвер NVIDIA версии: ${GREEN}$driver_version${NC}"
    
    return 0
}

# Установка CUDA
install_cuda() {
    # Проверка драйвера перед установкой
    if ! check_nvidia_driver; then
        exit 1
    fi

    echo -e "${YELLOW}Установка CUDA...${NC}"
    
    # Добавление CUDA репозитория
    wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin
    sudo mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
    
    # Загрузка и установка пакета CUDA
    wget https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda-repo-wsl-ubuntu-12-8-local_12.8.0-1_amd64.deb
    sudo dpkg -i cuda-repo-wsl-ubuntu-12-8-local_12.8.0-1_amd64.deb
    sudo cp /var/cuda-repo-wsl-ubuntu-12-8-local/cuda-*-keyring.gpg /usr/share/keyrings/
    
    # Установка CUDA toolkit
    sudo apt-get update
    sudo apt-get -y install cuda-toolkit-12-8
    
    # Очистка
    rm -f cuda-repo-wsl-ubuntu-12-8-local_12.8.0-1_amd64.deb
    
    # Проверка установки
    if command -v nvcc &> /dev/null; then
        local cuda_version
        cuda_version=$(nvcc --version | grep "release" | awk '{print $5}' | cut -d',' -f1)
        echo -e "${GREEN}CUDA $cuda_version успешно установлена${NC}"
    else
        echo -e "${RED}Ошибка: CUDA не установлена${NC}"
        return 1
    fi
}

# Запуск установки
install_cuda

echo -e "${GREEN}Для проверки выполните:${NC}"
echo "nvidia-smi"
echo "nvcc --version"