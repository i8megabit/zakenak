#!/bin/bash

# Цветовые коды
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Минимальные версии
MIN_DRIVER_VERSION="535.104.05"

# Проверка GPU и драйвера
check_gpu() {
    echo -e "${YELLOW}Проверка GPU и драйвера NVIDIA...${NC}"
    
    # Проверка nvidia-smi
    if ! nvidia-smi &> /dev/null; then
        echo -e "${RED}nvidia-smi не найден. Установите драйвер NVIDIA для WSL2${NC}"
        return 1
    fi
    
    # Проверка версии драйвера
    local driver_version
    driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
    echo -e "Версия драйвера NVIDIA: ${GREEN}$driver_version${NC}"
    
    # Проверка GPU устройств
    local gpu_count
    gpu_count=$(nvidia-smi --query-gpu=gpu_name --format=csv,noheader | wc -l)
    if [ "$gpu_count" -eq 0 ]; then
        echo -e "${RED}GPU устройства не обнаружены${NC}"
        return 1
    fi
    
    echo -e "Обнаружено GPU устройств: ${GREEN}$gpu_count${NC}"
    nvidia-smi --query-gpu=gpu_name,memory.total --format=csv,noheader
    
    return 0
}

# Проверка NVIDIA Container Toolkit
check_nvidia_toolkit() {
    echo -e "${YELLOW}Проверка NVIDIA Container Toolkit...${NC}"
    
    # Проверка установки
    if ! dpkg -l | grep -q nvidia-container-toolkit; then
        echo -e "${RED}NVIDIA Container Toolkit не установлен${NC}"
        return 1
    fi
    
    # Проверка конфигурации Docker
    if ! grep -q "nvidia-container-runtime" /etc/docker/daemon.json 2>/dev/null; then
        echo -e "${RED}NVIDIA Container Runtime не настроен в Docker${NC}"
        return 1
    fi
    
    # Тестовый запуск контейнера
    echo "Проверка GPU в контейнере..."
    if ! docker run --rm --gpus all nvidia/cuda:12.6.1-base-ubuntu22.04 nvidia-smi &>/dev/null; then
        echo -e "${RED}Ошибка при запуске GPU в контейнере${NC}"
        return 1
    fi
    
    echo -e "${GREEN}NVIDIA Container Toolkit настроен корректно${NC}"
    return 0
}

# Основная функция
main() {
    echo -e "${YELLOW}Запуск проверки GPU компонентов...${NC}"
    
    # Проверка GPU и драйвера
    if ! check_gpu; then
        echo -e "${RED}Ошибка: Проверка GPU не пройдена${NC}"
        return 1
    fi
    
    # Проверка NVIDIA Container Toolkit
    if ! check_nvidia_toolkit; then
        echo -e "${RED}Ошибка: Проверка NVIDIA Container Toolkit не пройдена${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Все компоненты GPU успешно проверены!${NC}"
    return 0
}

# Запуск основной функции
main