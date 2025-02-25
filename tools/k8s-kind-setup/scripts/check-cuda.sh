
#!/bin/bash

# Цветовые коды
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Минимальные версии
MIN_DRIVER_VERSION="535.104.05"
MIN_CUDA_VERSION="12.8"

echo -e "${YELLOW}Проверка поддержки CUDA в WSL...${NC}"

# Проверка nvidia-smi
echo -e "\n${YELLOW}1. Проверка драйвера NVIDIA:${NC}"
if command -v nvidia-smi &> /dev/null; then
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

# Проверка версии CUDA
echo -e "\n${YELLOW}2. Проверка версии CUDA:${NC}"
if command -v nvcc &> /dev/null; then
    CUDA_VERSION=$(nvcc --version | grep "release" | awk '{print $5}' | cut -d',' -f1)
    echo -e "Версия CUDA: $CUDA_VERSION"
    if awk -v v1="$CUDA_VERSION" -v v2="$MIN_CUDA_VERSION" 'BEGIN{if (v1 >= v2) exit 0; else exit 1}'; then
        echo -e "${GREEN}✓ Версия CUDA совместима (>= $MIN_CUDA_VERSION)${NC}"
    else
        echo -e "${RED}✗ Версия CUDA ниже требуемой${NC}"
        echo -e "${YELLOW}Текущая версия: $CUDA_VERSION${NC}"
    fi
else
    echo -e "${RED}✗ CUDA toolkit не установлен${NC}"
fi

# Проверка библиотек CUDA
echo -e "\n${YELLOW}3. Проверка библиотек CUDA:${NC}"
if [ -d "/usr/local/cuda/lib64" ]; then
    echo -e "${GREEN}✓ Библиотеки CUDA найдены в /usr/local/cuda/lib64${NC}"
    ls -l /usr/local/cuda/lib64/libcud*.so* 2>/dev/null
else
    echo -e "${RED}✗ Библиотеки CUDA не найдены${NC}"
fi

# Проверка библиотек NVIDIA для WSL
echo -e "\n${YELLOW}4. Проверка библиотек NVIDIA для WSL:${NC}"
if [ -d "/usr/lib/wsl/lib" ]; then
    echo -e "${GREEN}✓ Библиотеки NVIDIA для WSL найдены${NC}"
    ls -l /usr/lib/wsl/lib/libcud*.so* 2>/dev/null
else
    echo -e "${RED}✗ Библиотеки NVIDIA для WSL не найдены${NC}"
fi

# Тестирование возможностей CUDA
echo -e "\n${YELLOW}5. Тестирование CUDA:${NC}"
cat << EOF > /tmp/cuda_test.cu
#include <stdio.h>

int main() {
    cudaDeviceProp prop;
    int count;
    
    cudaError_t error = cudaGetDeviceCount(&count);
    if (error != cudaSuccess) {
        printf("Ошибка: %s\n", cudaGetErrorString(error));
        return -1;
    }
    
    for (int i = 0; i < count; i++) {
        cudaGetDeviceProperties(&prop, i);
        printf("Устройство %d: %s\n", i, prop.name);
        printf("  Вычислительная способность: %d.%d\n", prop.major, prop.minor);
        printf("  Общая память: %.2f ГБ\n", prop.totalGlobalMem / (1024.0 * 1024.0 * 1024.0));
    }
    return 0;
}
EOF

if command -v nvcc &> /dev/null; then
    echo "Компиляция тестовой программы CUDA..."
    if nvcc /tmp/cuda_test.cu -o /tmp/cuda_test; then
        echo -e "${GREEN}✓ Компиляция CUDA успешна${NC}"
        echo "Запуск теста CUDA..."
        /tmp/cuda_test
    else
        echo -e "${RED}✗ Ошибка компиляции CUDA${NC}"
    fi
else
    echo -e "${RED}✗ Невозможно протестировать CUDA - nvcc не найден${NC}"
fi

# Очистка
rm -f /tmp/cuda_test.cu /tmp/cuda_test

echo -e "\n${YELLOW}Итоги:${NC}"
echo "Для использования CUDA $MIN_CUDA_VERSION в WSL необходимо:"
echo "1. Драйвер NVIDIA с поддержкой CUDA $MIN_CUDA_VERSION (минимум $MIN_DRIVER_VERSION)"
echo "2. Установленный CUDA Toolkit $MIN_CUDA_VERSION"
echo "3. Корректная настройка WSL2 с поддержкой NVIDIA"
echo "4. GPU с соответствующей вычислительной способностью"