swap=8GB
localhostForwarding=true
kernelCommandLine=systemd=true
EOF
}

# Функция установки зависимостей
install_dependencies() {
    log "Installing dependencies..."
    sudo apt-get update && sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common \
        gnupg \
        make \
        wget
}

# Функция установки CUDA
install_cuda() {
    log "Installing CUDA ${CUDA_VERSION}..."
    wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin
    sudo mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
    wget https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}.0/local_installers/cuda-repo-wsl-ubuntu-${CUDA_VERSION}-local_${CUDA_VERSION}.0-1_amd64.deb
    sudo dpkg -i cuda-repo-wsl-ubuntu-${CUDA_VERSION}-local_${CUDA_VERSION}.0-1_amd64.deb
    sudo cp /var/cuda-repo-wsl-ubuntu-${CUDA_VERSION}-local/cuda-*-keyring.gpg /usr/share/keyrings/
    sudo apt-get update
    sudo apt-get -y install cuda-toolkit-${CUDA_VERSION}
}

# Функция установки Docker
install_docker() {
    log "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
}

# Функция настройки NVIDIA Container Toolkit
setup_nvidia_container_toolkit() {
    log "Setting up NVIDIA Container Toolkit..."
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
}

# Функция проверки установки
verify_installation() {
    log "Verifying installation..."
    
    # Проверка CUDA
    if ! command -v nvcc &> /dev/null; then
        error_handler "CUDA installation failed"
    }
    
    # Проверка Docker
    if ! docker info &> /dev/null; then
        error_handler "Docker installation failed"
    }
    
    # Проверка NVIDIA Container Toolkit
    if ! docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
        error_handler "NVIDIA Container Toolkit verification failed"
    }
}

# Основная функция
main() {
    log "Starting WSL2 setup (v${SCRIPT_VERSION})..."
    
    check_requirements
    configure_wsl
    install_dependencies
    install_cuda
    install_docker
    setup_nvidia_container_toolkit
    verify_installation

    log "WSL2 setup completed successfully!"
    log "Please restart your WSL instance for changes to take effect."
}

main "$@"