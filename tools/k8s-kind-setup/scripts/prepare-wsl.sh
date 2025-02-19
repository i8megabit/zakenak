#!/bin/bash
set -euo pipefail

# Глобальные переменные
CUDA_VERSION="12.8"
DOCKER_COMPOSE_VERSION="v2.24.0"
MIN_MEMORY="16"
MIN_PROCESSORS="4"
MIN_SWAP="8"

# Функции логирования
log_info() {
	echo "[INFO] $1"
}

log_error() {
	echo "[ERROR] $1" >&2
}

log_warning() {
	echo "[WARNING] $1" >&2
}

# Проверка системных требований
check_system_requirements() {
	log_info "Проверка системных требований..."
	
	if ! grep -q microsoft /proc/version; then
		log_error "Этот скрипт должен быть запущен в WSL2"
		exit 1
	fi

	# Проверка памяти
	total_memory=$(free -g | awk '/^Mem:/{print $2}')
	if [ "${total_memory}" -lt "${MIN_MEMORY}" ]; then
		log_error "Недостаточно памяти. Требуется минимум ${MIN_MEMORY}GB"
		exit 1
	fi

	# Проверка процессоров
	cpu_count=$(nproc)
	if [ "${cpu_count}" -lt "${MIN_PROCESSORS}" ]; then
		log_error "Недостаточно процессоров. Требуется минимум ${MIN_PROCESSORS}"
		exit 1
	fi
}

# Настройка WSL2
configure_wsl() {
	log_info "Настройка WSL2..."
	cat << EOF > "${HOME}/.wslconfig"
[wsl2]
memory=${MIN_MEMORY}GB
processors=${MIN_PROCESSORS}
swap=${MIN_SWAP}GB
localhostForwarding=true
kernelCommandLine=systemd=true
EOF
}

# Установка базовых зависимостей
install_dependencies() {
	log_info "Установка базовых зависимостей..."
	sudo apt-get update && sudo apt-get install -y \
		apt-transport-https \
		ca-certificates \
		curl \
		software-properties-common \
		gnupg \
		make \
		git
}

# Установка CUDA
install_cuda() {
	log_info "Установка CUDA ${CUDA_VERSION}..."
	
	# Скачивание и установка CUDA
	wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin
	sudo mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
	wget https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}.0/local_installers/cuda-repo-wsl-ubuntu-${CUDA_VERSION}-local_${CUDA_VERSION}.0-1_amd64.deb
	sudo dpkg -i cuda-repo-wsl-ubuntu-${CUDA_VERSION}-local_${CUDA_VERSION}.0-1_amd64.deb
	sudo cp /var/cuda-repo-wsl-ubuntu-${CUDA_VERSION}-local/cuda-*-keyring.gpg /usr/share/keyrings/
	sudo apt-get update
	sudo apt-get -y install cuda-toolkit-${CUDA_VERSION}

	# Проверка установки
	if ! command -v nvcc &> /dev/null; then
		log_error "Ошибка установки CUDA"
		exit 1
	fi
}

# Установка Docker
install_docker() {
	log_info "Установка Docker..."
	curl -fsSL https://get.docker.com -o get-docker.sh
	sudo sh get-docker.sh

	# Настройка пользователя
	sudo usermod -aG docker $USER

	# Установка Docker Compose
	sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
}

# Настройка NVIDIA Container Toolkit
setup_nvidia_container_toolkit() {
	log_info "Настройка NVIDIA Container Toolkit..."
	distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
	curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
	curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
		sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

	sudo apt-get update
	sudo apt-get install -y nvidia-container-toolkit
	sudo nvidia-ctk runtime configure --runtime=docker
	sudo systemctl restart docker
}

# Проверка установки
verify_installation() {
	log_info "Проверка установки..."
	
	# Проверка CUDA
	if ! nvidia-smi &> /dev/null; then
		log_error "Ошибка проверки NVIDIA драйверов"
		exit 1
	fi

	# Проверка Docker с GPU
	if ! docker run --rm --gpus all nvidia/cuda:${CUDA_VERSION}.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
		log_error "Ошибка проверки Docker с GPU"
		exit 1
	fi

	log_info "Установка успешно завершена!"
}

# Основная функция
main() {
	log_info "Начало подготовки WSL окружения..."
	
	check_system_requirements
	configure_wsl
	install_dependencies
	install_cuda
	install_docker
	setup_nvidia_container_toolkit
	verify_installation
	
	log_info "Подготовка WSL окружения завершена успешно!"
}

main "$@"