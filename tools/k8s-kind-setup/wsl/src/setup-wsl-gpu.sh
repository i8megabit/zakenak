#!/usr/bin/bash

# Проверка версии Windows
check_windows_version() {
    if ! grep -q "microsoft" /proc/version &> /dev/null; then
        echo "Этот скрипт должен выполняться в WSL2"
        return 1
    fi
    return 0
}

# Проверка наличия NVIDIA драйверов
check_nvidia_drivers() {
    if ! command -v nvidia-smi &> /dev/null; then
        echo "NVIDIA драйверы не установлены. Установите последнюю версию драйвера для RTX 4080"
        echo "Ссылка: https://www.nvidia.ru/Download/index.aspx"
        return 1
    fi
    
    # Проверка поддержки CUDA
    if ! nvidia-smi | grep -q "CUDA Version"; then
        echo "CUDA не обнаружена"
        return 1
    fi
    
    # Проверка тензорных ядер
    if ! nvidia-smi -q | grep -q "Tensor Cores"; then
        echo "Тензорные ядра не обнаружены"
        return 1
    }
    
    return 0
}

# Установка CUDA toolkit
install_cuda_toolkit() {
    # Установка базовых зависимостей
    sudo apt-get update
    sudo apt-get install -y wget build-essential

    # Установка CUDA toolkit
    wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin
    sudo mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
    wget https://developer.download.nvidia.com/compute/cuda/12.3.1/local_installers/cuda-repo-wsl-ubuntu-12-3-local_12.3.1-1_amd64.deb
    sudo dpkg -i cuda-repo-wsl-ubuntu-12-3-local_12.3.1-1_amd64.deb
    sudo cp /var/cuda-repo-wsl-ubuntu-12-3-local/cuda-*-keyring.gpg /usr/share/keyrings/
    sudo apt-get update
    sudo apt-get -y install cuda-toolkit-12-3
}

# Установка NVIDIA Container Toolkit
install_nvidia_container_toolkit() {
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
}

# Настройка переменных окружения для CUDA
setup_cuda_env() {
    echo 'export PATH=/usr/local/cuda-12.3/bin${PATH:+:${PATH}}' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.3/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc
    source ~/.bashrc
}

# Проверка GPU в Docker с тензорными операциями
test_gpu_docker() {
    echo "Тестирование GPU в Docker..."
    if ! docker run --gpus all nvcr.io/nvidia/cuda:12.3.1-base-ubuntu22.04 nvidia-smi; then
        echo "Ошибка при тестировании базового GPU в Docker"
        return 1
    fi

    echo "Тестирование TensorFlow с GPU..."
    if ! docker run --gpus all -it --rm nvcr.io/nvidia/tensorflow:23.12-tf2-py3 python3 -c \
        "import tensorflow as tf; print('Количество доступных GPU:', len(tf.config.list_physical_devices('GPU')))"; then
        echo "Ошибка при тестировании TensorFlow"
        return 1
    fi
    
    return 0
}

# Основная функция
main() {
    echo "Начало настройки GPU RTX 4080 в WSL2..."
    
    if ! check_windows_version; then
        exit 1
    fi

    if ! check_nvidia_drivers; then
        exit 1
    fi

    echo "Установка CUDA Toolkit..."
    if ! install_cuda_toolkit; then
        echo "Ошибка при установке CUDA Toolkit"
        exit 1
    fi

    echo "Установка NVIDIA Container Toolkit..."
    if ! install_nvidia_container_toolkit; then
        echo "Ошибка при установке NVIDIA Container Toolkit"
        exit 1
    fi

    echo "Настройка переменных окружения CUDA..."
    setup_cuda_env

    echo "Тестирование GPU..."
    if ! test_gpu_docker; then
        echo "Ошибка при тестировании GPU"
        exit 1
    fi

    echo "Настройка GPU RTX 4080 в WSL2 успешно завершена!"
    echo "Для использования GPU в kind-кластере используйте конфигурацию из kind-config-gpu.yml"
}

main "$@" 