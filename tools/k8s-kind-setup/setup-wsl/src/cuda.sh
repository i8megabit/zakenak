#!/bin/bash
set -e

# Цветовые коды
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Минимальные версии
MIN_DRIVER_VERSION="535.104.05"
MIN_CUDA_VERSION="12.6"

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

    echo -e "${YELLOW}Очистка предыдущей установки CUDA...${NC}"
    
    # Удаление поврежденных пакетов
    sudo apt-get remove --purge -y cuda* nvidia-cuda* libcublas* libcufft* libcusparse* nsight-compute*
    sudo apt-get autoremove -y
    sudo apt-get clean
    
    # Очистка кэша apt
    sudo rm -rf /var/lib/apt/lists/*
    sudo rm -f /etc/apt/preferences.d/cuda-repository-pin-600
    
    echo -e "${YELLOW}Установка CUDA...${NC}"
    
    # Обновление списка пакетов
    sudo apt-get update
    
    # Добавление CUDA репозитория с повторными попытками
    for i in {1..3}; do
        if wget --tries=3 https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin; then
            sudo mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
            break
        fi
        echo -e "${YELLOW}Попытка $i загрузки cuda-wsl-ubuntu.pin не удалась, повторная попытка...${NC}"
        sleep 2
    done
    
    # Загрузка и установка пакета CUDA с проверкой
    local cuda_deb="cuda-repo-wsl-ubuntu-12-6-local_12.6.0-1_amd64.deb"
    for i in {1..3}; do
        echo -e "${YELLOW}Попытка $i загрузки CUDA...${NC}"
        if wget --continue https://developer.download.nvidia.com/compute/cuda/12.6.0/local_installers/$cuda_deb; then
            # Проверка целостности файла
            if [ -f $cuda_deb ] && [ $(stat -c%s "$cuda_deb") -gt 1000000000 ]; then
                break
            fi
        fi
        rm -f $cuda_deb
        sleep 2
    done

    if [ ! -f $cuda_deb ]; then
        echo -e "${RED}Не удалось загрузить CUDA пакет${NC}"
        exit 1
    fi

    # Установка CUDA
    sudo dpkg -i $cuda_deb
    sudo cp /var/cuda-repo-wsl-ubuntu-12-6-local/cuda-*-keyring.gpg /usr/share/keyrings/
    
    # Установка CUDA toolkit с повторными попытками
    sudo apt-get update
    for i in {1..3}; do
        if sudo apt-get -y install cuda-toolkit-12-6; then
            break
        fi
        echo -e "${YELLOW}Попытка $i установки CUDA toolkit не удалась, повторная попытка...${NC}"
        sudo apt-get clean
        sleep 2
    done
    
    # Очистка
    rm -f $cuda_deb
    
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