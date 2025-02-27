
#!/bin/bash

# Цветовые коды
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Минимальные версии
MIN_DRIVER_VERSION="535.104.05"

echo -e "${YELLOW}Проверка поддержки GPU в WSL...${NC}"

# Проверка nvidia-smi
echo -e "\n${YELLOW}1. Проверка драйвера NVIDIA:${NC}"
if nvidia-smi &> /dev/null; then
    DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
    echo "Версия драйвера: $DRIVER_VERSION"
    
    if awk -v v1="$DRIVER_VERSION" -v v2="$MIN_DRIVER_VERSION" 'BEGIN{if (v1 >= v2) exit 0; else exit 1}'; then
        echo -e "${GREEN}✓ Драйвер NVIDIA установлен и соответствует требованиям${NC}"
    else
        echo -e "${RED}✗ Версия драйвера ниже требуемой ($MIN_DRIVER_VERSION)${NC}"
        exit 1
    fi
    
    # Проверка модели GPU
    GPU_NAME=$(nvidia-smi --query-gpu=gpu_name --format=csv,noheader)
    echo -e "Модель GPU: $GPU_NAME"
else
    echo -e "${RED}✗ Драйвер NVIDIA не установлен${NC}"
    exit 1
fi

# Проверка библиотек NVIDIA для WSL
echo -e "\n${YELLOW}2. Проверка библиотек NVIDIA для WSL:${NC}"
if [ -d "/usr/lib/wsl/lib" ]; then
    echo -e "${GREEN}✓ Библиотеки NVIDIA для WSL найдены${NC}"
    ls -l /usr/lib/wsl/lib/libcud*.so* 2>/dev/null
else
    echo -e "${RED}✗ Библиотеки NVIDIA для WSL не найдены${NC}"
fi

# Проверка NVIDIA Container Toolkit
echo -e "\n${YELLOW}3. Проверка NVIDIA Container Toolkit:${NC}"
if docker run --rm --gpus all nvidia/cuda:12.6.1-base-ubuntu22.04 nvidia-smi &> /dev/null; then
    echo -e "${GREEN}✓ NVIDIA Container Toolkit работает корректно${NC}"
    docker run --rm --gpus all nvidia/cuda:12.6.1-base-ubuntu22.04 nvidia-smi | head -n 3
else
    echo -e "${RED}✗ Проблема с NVIDIA Container Toolkit${NC}"
    echo "Проверьте настройку Docker и NVIDIA Container Toolkit"
fi

echo -e "\n${YELLOW}Итоги:${NC}"
echo "Для использования GPU в WSL необходимо:"
echo "1. Драйвер NVIDIA (минимум $MIN_DRIVER_VERSION)"
echo "2. Корректная настройка WSL2 с поддержкой NVIDIA"
echo "3. Настроенный NVIDIA Container Toolkit"
echo "4. GPU с соответствующей вычислительной способностью"