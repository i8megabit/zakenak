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
echo -e "${YELLOW}ВНИМАНИЕ: Необходимо создать файл .wslconfig в Windows${NC}"
echo -e "${YELLOW}Выполните в PowerShell на Windows:${NC}"
echo -e "${YELLOW}notepad \"\$env:USERPROFILE\\.wslconfig\"${NC}"
echo -e "${YELLOW}И добавьте следующие настройки:${NC}"
echo -e "${YELLOW}[boot]${NC}"
echo -e "${YELLOW}systemd=true${NC}"
echo -e "${YELLOW}[wsl2]${NC}"
echo -e "${YELLOW}memory=40GB${NC}"
echo -e "${YELLOW}processors=12${NC}"
echo -e "${YELLOW}swap=16GB${NC}"
echo -e "${YELLOW}localhostForwarding=true${NC}"
echo -e "${YELLOW}kernelCommandLine=cgroup_no_v1=all cgroup_enable=memory swapaccount=1${NC}"
echo -e "${YELLOW}nestedVirtualization=true${NC}"
echo -e "${YELLOW}guiApplications=true${NC}"
echo -e "${YELLOW}debugConsole=false${NC}"
echo -e "${YELLOW}[experimental]${NC}"
echo -e "${YELLOW}hostAddressLoopback=true${NC}"
echo -e "${YELLOW}bestEffortDnsParsing=true${NC}"
echo -e "${YELLOW}После этого перезапустите WSL командой: wsl --shutdown${NC}"

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

# Проверка настройки TensorFlow с GPU
echo "Проверка TensorFlow с GPU..."
echo -e "${YELLOW}Тестируем совместимость с TensorFlow...${NC}"

# Запускаем контейнер с TensorFlow для проверки GPU
if docker run --rm --gpus all -it --shm-size=1g --ulimit memlock=-1 --ulimit stack=67108864 nvcr.io/nvidia/tensorflow:23.11-tf2-py3 \
    python -c "import tensorflow as tf; print('Доступные GPU:', tf.config.list_physical_devices('GPU'))" 2>&1 | grep -q "Доступные GPU: \["; then
    echo -e "${GREEN}TensorFlow с GPU работает корректно!${NC}"
else
    echo -e "${RED}Проблема с TensorFlow и GPU${NC}"
    echo -e "${YELLOW}Возможные причины:${NC}"
    echo "1. Несовместимость версии контейнера с драйвером"
    echo "2. Проблемы с настройкой NVIDIA Container Toolkit"
    echo "3. Проблемы с доступом к GPU из Docker"
    echo ""
    echo -e "${YELLOW}Рекомендации:${NC}"
    echo "1. Используйте более новую версию контейнера, например: nvcr.io/nvidia/tensorflow:23.11-tf2-py3"
    echo "2. Если вы используете стандартный Docker (не Docker Desktop), перезапустите его: sudo systemctl restart docker"
    echo "3. Убедитесь, что NVIDIA драйвер совместим с контейнером"
    echo ""
    echo -e "${YELLOW}Диагностика:${NC}"
    docker run --rm --gpus all nvidia/cuda:12.6.1-base-ubuntu22.04 nvidia-smi || true
fi

# Проверка PyTorch с GPU
echo "Проверка PyTorch с GPU..."
echo -e "${YELLOW}Тестируем совместимость с PyTorch...${NC}"

# Запускаем контейнер с PyTorch для проверки GPU
if docker run --rm --gpus all -it nvcr.io/nvidia/pytorch:23.12-py3 \
    python -c "import torch; print('CUDA доступен:', torch.cuda.is_available()); print('Устройство GPU:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'Нет')" 2>&1 | grep -q "CUDA доступен: True"; then
    echo -e "${GREEN}PyTorch с GPU работает корректно!${NC}"
else
    echo -e "${RED}Проблема с PyTorch и GPU${NC}"
    echo -e "${YELLOW}Возможные причины:${NC}"
    echo "1. Несовместимость версии контейнера с драйвером"
    echo "2. Проблемы с настройкой NVIDIA Container Toolkit"
    echo "3. Проблемы с доступом к GPU из Docker"
    echo ""
    echo -e "${YELLOW}Диагностика:${NC}"
    docker run --rm --gpus all nvidia/cuda:12.6.1-base-ubuntu22.04 nvidia-smi || true
fi

echo -e "${GREEN}Настройка WSL2 успешно завершена!${NC}"
echo -e "${YELLOW}Для применения изменений выполните:${NC}"
echo "1. wsl --shutdown (в PowerShell на Windows)"
if is_docker_desktop; then
    echo "2. Перезапустите Docker Desktop из Windows"
else
    echo "2. Перезапустите Docker: sudo systemctl restart docker"
fi
echo -e "${YELLOW}Для проверки GPU выполните:${NC}"
echo "nvidia-smi"
echo "docker run --rm --gpus all nvidia/cuda:12.6.1-base-ubuntu22.04 nvidia-smi"
echo -e "${YELLOW}Для проверки тензоров выполните:${NC}"
echo "docker run --rm --gpus all nvcr.io/nvidia/tensorflow:23.11-tf2-py3 python -c \"import tensorflow as tf; print('Доступные GPU:', tf.config.list_physical_devices('GPU'))\""
echo "docker run --rm --gpus all nvcr.io/nvidia/pytorch:23.12-py3 python -c \"import torch; print('CUDA доступен:', torch.cuda.is_available()); print('Устройство GPU:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'Нет')\""