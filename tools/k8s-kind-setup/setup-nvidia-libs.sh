#!/usr/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Установка библиотек NVIDIA для WSL2...${NC}"

# Проверка наличия nvidia-smi
if ! command -v nvidia-smi &> /dev/null; then
    echo -e "${RED}Ошибка: nvidia-smi не найден${NC}"
    echo -e "Убедитесь, что драйвер NVIDIA установлен в Windows и WSL2 настроен для работы с GPU"
    exit 1
fi

# Проверка версии драйвера
DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
echo -e "Обнаружен драйвер NVIDIA версии: ${GREEN}$DRIVER_VERSION${NC}"

# Проверка модели GPU
GPU_MODEL=$(nvidia-smi --query-gpu=gpu_name --format=csv,noheader)
echo -e "Модель GPU: ${GREEN}$GPU_MODEL${NC}"

# Установка необходимых пакетов
echo -e "${CYAN}Установка необходимых пакетов...${NC}"
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    nvidia-container-toolkit \
    nvidia-container-runtime \
    libnvidia-compute-535 \
    libnvidia-extra-535 \
    libnvidia-decode-535 \
    libnvidia-encode-535 \
    libnvidia-fbc1-535

# Проверка наличия библиотеки libnvidia-ml.so.1
echo -e "${CYAN}Проверка наличия библиотеки libnvidia-ml.so.1...${NC}"
if [ -f /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1 ]; then
    echo -e "${GREEN}Библиотека libnvidia-ml.so.1 найдена в /usr/lib/x86_64-linux-gnu/${NC}"
else
    echo -e "${YELLOW}Библиотека libnvidia-ml.so.1 не найдена в /usr/lib/x86_64-linux-gnu/${NC}"
    
    # Поиск библиотеки в других местах
    NVML_LIB=$(find /usr -name "libnvidia-ml.so.1" 2>/dev/null | head -n 1)
    
    if [ -n "$NVML_LIB" ]; then
        echo -e "${GREEN}Библиотека libnvidia-ml.so.1 найдена в $NVML_LIB${NC}"
        echo -e "${CYAN}Создание символической ссылки...${NC}"
        sudo ln -sf "$NVML_LIB" /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1
        echo -e "${GREEN}Символическая ссылка создана${NC}"
    else
        echo -e "${RED}Библиотека libnvidia-ml.so.1 не найдена в системе${NC}"
        echo -e "${YELLOW}Попытка установки драйвера NVIDIA...${NC}"
        
        # Установка драйвера NVIDIA для WSL
        sudo apt-get install -y nvidia-driver-535
        
        # Повторная проверка
        if [ -f /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1 ]; then
            echo -e "${GREEN}Библиотека libnvidia-ml.so.1 успешно установлена${NC}"
        else
            echo -e "${RED}Не удалось установить библиотеку libnvidia-ml.so.1${NC}"
            echo -e "${YELLOW}Попробуйте установить драйвер NVIDIA вручную:${NC}"
            echo -e "sudo apt-get install -y nvidia-driver-535"
            exit 1
        fi
    fi
fi

# Проверка наличия библиотеки в /usr/lib/wsl/lib
echo -e "${CYAN}Проверка наличия библиотеки в /usr/lib/wsl/lib...${NC}"
if [ -d /usr/lib/wsl/lib ]; then
    if [ -f /usr/lib/wsl/lib/libnvidia-ml.so.1 ]; then
        echo -e "${GREEN}Библиотека libnvidia-ml.so.1 найдена в /usr/lib/wsl/lib/${NC}"
    else
        echo -e "${YELLOW}Библиотека libnvidia-ml.so.1 не найдена в /usr/lib/wsl/lib/${NC}"
        echo -e "${CYAN}Создание символической ссылки...${NC}"
        sudo mkdir -p /usr/lib/wsl/lib
        sudo ln -sf /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1 /usr/lib/wsl/lib/libnvidia-ml.so.1
        echo -e "${GREEN}Символическая ссылка создана${NC}"
    fi
else
    echo -e "${YELLOW}Директория /usr/lib/wsl/lib не найдена${NC}"
    echo -e "${CYAN}Создание директории и символической ссылки...${NC}"
    sudo mkdir -p /usr/lib/wsl/lib
    sudo ln -sf /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1 /usr/lib/wsl/lib/libnvidia-ml.so.1
    echo -e "${GREEN}Директория и символическая ссылка созданы${NC}"
fi

# Настройка NVIDIA Container Toolkit
echo -e "${CYAN}Настройка NVIDIA Container Toolkit...${NC}"
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker || sudo service docker restart

# Проверка работы NVIDIA в контейнере
echo -e "${CYAN}Проверка работы NVIDIA в контейнере...${NC}"
if docker run --rm --gpus all nvidia/cuda:12.6.1-base-ubuntu22.04 nvidia-smi &>/dev/null; then
    echo -e "${GREEN}NVIDIA Container Toolkit настроен корректно${NC}"
    docker run --rm --gpus all nvidia/cuda:12.6.1-base-ubuntu22.04 nvidia-smi | head -n 3
else
    echo -e "${RED}Ошибка при запуске GPU в контейнере${NC}"
    echo -e "${YELLOW}Проверьте настройку Docker и NVIDIA Container Toolkit${NC}"
    exit 1
fi

echo -e "${GREEN}Установка библиотек NVIDIA для WSL2 завершена успешно${NC}"
echo -e "${YELLOW}Теперь вы можете запустить скрипт настройки кластера KIND:${NC}"
echo -e "${CYAN}./tools/k8s-kind-setup/deploy-all/src/deploy-all.sh --auto-install${NC}"