#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Log functions
log_info() {
	echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
	echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
	log_error "Please run as root"
	exit 1
fi

# Check system requirements
check_requirements() {
	log_info "Checking system requirements..."
	
	# Check memory
	total_mem=$(free -g | awk '/^Mem:/{print $2}')
	if [ "$total_mem" -lt 16 ]; then
		log_warn "Less than 16GB RAM detected. This may impact performance."
	fi

	# Check for NVIDIA GPU
	if ! command -v nvidia-smi &> /dev/null; then
		log_error "NVIDIA GPU drivers not found"
		exit 1
	fi
}


# Install required packages
install_prerequisites() {
	log_info "Installing prerequisites..."
	apt-get update
	apt-get install -y \
		wget \
		curl \
		gnupg2 \
		apt-transport-https \
		ca-certificates \
		software-properties-common
}

# Install Docker for non-WSL environment
install_docker() {
	log_info "Installing Docker..."
	
	# Remove old versions
	apt-get remove -y docker docker-engine docker.io containerd runc || true
	
	# Add Docker repository
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
	
	echo \
		"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
		$(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
	
	apt-get update
	apt-get install -y docker-ce docker-ce-cli containerd.io
	
	# Add current user to docker group
	usermod -aG docker $SUDO_USER
	
	# Start and enable Docker
	systemctl enable docker
	systemctl start docker
}

# Install NVIDIA Container Toolkit
install_nvidia_toolkit() {
	log_info "Installing NVIDIA Container Toolkit..."
	
	# Create keyrings directory if it doesn't exist
	sudo mkdir -p /usr/share/keyrings

	# Remove old repository configuration if exists
	sudo rm -f /etc/apt/sources.list.d/nvidia-container-toolkit.list || true
	
	# Add NVIDIA repository key with proper error handling
	if ! curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg; then
		log_error "Failed to add NVIDIA GPG key"
		exit 1
	fi
	
	# Add repository with architecture detection
	ARCH=$(dpkg --print-architecture)
	echo "deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://nvidia.github.io/libnvidia-container/stable/deb/${ARCH} /" | \
		sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

	# Update package list with retry mechanism
	local max_attempts=3
	local attempt=1
	while [ $attempt -le $max_attempts ]; do
		log_info "Updating package list (attempt ${attempt}/${max_attempts})..."
		if sudo apt-get update; then
			break
		fi
		attempt=$((attempt + 1))
		if [ $attempt -le $max_attempts ]; then
			log_warn "apt-get update failed, retrying in 5 seconds..."
			sleep 5
		else
			log_error "Failed to update package list after ${max_attempts} attempts"
			exit 1
		fi
	done

	# Install NVIDIA Container Toolkit
	if ! sudo apt-get install -y nvidia-container-toolkit; then
		log_error "Failed to install nvidia-container-toolkit"
		exit 1
	fi

	# Configure Docker runtime
	if ! sudo nvidia-ctk runtime configure --runtime=docker; then
		log_error "Failed to configure Docker runtime"
		exit 1
	fi

	# Restart Docker service
	if ! sudo systemctl restart docker; then
		log_error "Failed to restart Docker service"
		exit 1
	fi

	log_info "NVIDIA Container Toolkit installation completed successfully"
}

# Verify installation
verify_installation() {
	log_info "Verifying installation..."
	
	# Check Docker
	if ! docker info &> /dev/null; then
		log_error "Docker installation failed"
		exit 1
	fi
	
	# Check NVIDIA Container Toolkit
	if ! docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
		log_error "NVIDIA Container Toolkit installation failed"
		exit 1
	fi
	
	log_info "Installation successful!"
}

# Main installation process
main() {
	# Check if running in WSL
	if grep -q "microsoft" /proc/version; then
		log_info "WSL environment detected, skipping Docker installation..."
		check_requirements
		install_prerequisites
		install_nvidia_toolkit
		log_info "NVIDIA Container Toolkit setup completed successfully"
	else
		log_info "Starting Docker and NVIDIA Container Toolkit installation for native Linux..."
		check_requirements
		install_prerequisites
		install_docker
		install_nvidia_toolkit
		verify_installation
		log_info "Docker and NVIDIA Container Toolkit setup completed successfully"
		log_info "Please log out and log back in for group changes to take effect"
	fi
}

main
