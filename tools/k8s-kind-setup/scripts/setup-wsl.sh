#!/bin/bash
set -euo pipefail

# Определение версий и констант
CUDA_VERSION="12.8"
NVIDIA_DRIVER_MIN_VERSION="535.104.05"
REQUIRED_MEMORY="16"
WSL_DISTRO="Ubuntu-22.04"

echo "Starting WSL2 setup for Zakenak..."

# Функция проверки системных требований
check_requirements() {
	echo "Checking system requirements..."
	
	# Проверка WSL2
	if ! grep -q microsoft /proc/version; then
		echo "Error: This script must be run in WSL2"
		exit 1
	}

	# Проверка памяти
	total_mem=$(free -g | awk '/^Mem:/{print $2}')
	if [ "${total_mem}" -lt "${REQUIRED_MEMORY}" ]; then
		echo "Error: Minimum ${REQUIRED_MEMORY}GB RAM required"
		exit 1
	}

	# Проверка GPU
	if ! command -v nvidia-smi &> /dev/null; then
		echo "Error: NVIDIA GPU driver not found"
		exit 1
	}

	driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
	if ! awk -v ver="$driver_version" -v req="$NVIDIA_DRIVER_MIN_VERSION" 'BEGIN{exit!(ver>=req)}'; then
		echo "Error: NVIDIA driver version $NVIDIA_DRIVER_MIN_VERSION+ required"
		exit 1
	}
}

# Функция настройки WSL
configure_wsl() {
	echo "Configuring WSL2..."
	cat << EOF > "${HOME}/.wslconfig"
[wsl2]
memory=16GB
processors=4
swap=8GB
localhostForwarding=true
kernelCommandLine=systemd=true
EOF
}

# Функция установки зависимостей
install_dependencies() {
	echo "Installing dependencies..."
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
	echo "Installing CUDA ${CUDA_VERSION}..."
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
	echo "Installing Docker..."
	curl -fsSL https://get.docker.com -o get-docker.sh
	sudo sh get-docker.sh
}

# Функция настройки NVIDIA Container Toolkit
setup_nvidia_container_toolkit() {
	echo "Setting up NVIDIA Container Toolkit..."
	distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
	curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
	curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
		sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

	sudo apt-get update
	sudo apt-get install -y nvidia-container-toolkit
	sudo nvidia-ctk runtime configure --runtime=docker
	sudo systemctl restart docker
}

# Основная функция
main() {
	check_requirements
	configure_wsl
	install_dependencies
	install_cuda
	install_docker
	setup_nvidia_container_toolkit

	echo "WSL2 setup completed successfully!"
	echo "Please restart your WSL instance for changes to take effect."
}

main "$@"