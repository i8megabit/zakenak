#!/usr/bin/bash
#
# Environment variables for k8s-kind-setup scripts
#

# Define color codes for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# Define namespaces
export NAMESPACE_PROD="prod"
export NAMESPACE_DEV="dev"
export NAMESPACE_TEST="test"

# Define paths
export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export TOOLS_DIR="${BASE_DIR}/tools/k8s-kind-setup"
export SCRIPTS_ENV_PATH="${TOOLS_DIR}/env/src/env.sh"
export SCRIPTS_ASCII_BANNERS_PATH="${TOOLS_DIR}/ascii-banners/src/ascii_banners.sh"

# Define hosts
export DASHBOARD_HOST="dashboard.prod.local"
export OLLAMA_HOST="ollama.prod.local"
export WEBUI_HOST="webui.prod.local"

# Define ports
export DASHBOARD_PORT="443"
export OLLAMA_PORT="11434"
export WEBUI_PORT="8080"
#  _____ _   ___     __ 
# | ____| \ | \ \   / / 
# |  _| |  \| |\ \ / /  
# | |___| |\  | \ V /   
# |_____|_| \_|  \_/    
#              by @eberil
#
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# Environment Configuration
# Version: 1.0.0
#
# HUJAK-HUJAK PRODUCTION PRESENTS...
# "Because environment variables should be fun"

# Определение базовой директории проекта
export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export TOOLS_DIR="${BASE_DIR}/tools/k8s-kind-setup"

# Экспорт путей к скриптам (динамические пути)
export SCRIPTS_ENV_PATH="${TOOLS_DIR}/env/src/env.sh"
export SCRIPTS_ASCII_BANNERS_PATH="${TOOLS_DIR}/ascii-banners/src/ascii_banners.sh"
export SCRIPTS_SETUP_WSL_PATH="${TOOLS_DIR}/setup-wsl/src/setup-wsl.sh"
export SCRIPTS_SETUP_BINS_PATH="${TOOLS_DIR}/setup-bins/src/setup-bins.sh"
export SCRIPTS_SETUP_KIND_PATH="${TOOLS_DIR}/setup-kind/src/setup-kind.sh"
export SCRIPTS_SETUP_INGRESS_PATH="${TOOLS_DIR}/setup-ingress/src/setup-ingress.sh"
export SCRIPTS_SETUP_CERT_MANAGER_PATH="${TOOLS_DIR}/setup-cert-manager/src/setup-cert-manager.sh"
export SCRIPTS_SETUP_DNS_PATH="${TOOLS_DIR}/setup-dns/src/setup-dns.sh"
export SCRIPTS_DASHBOARD_TOKEN_PATH="${TOOLS_DIR}/dashboard-token/src/dashboard-token.sh"
export SCRIPTS_CHARTS_PATH="${TOOLS_DIR}/charts/src/charts.sh"
export SCRIPTS_CONNECTIVITY_CHECK_PATH="${TOOLS_DIR}/connectivity-check/src/check-services.sh"
export SCRIPTS_SETUP_NVIDIA_PATH="${TOOLS_DIR}/setup-nvidia/src/setup-nvidia.sh"


# Переменные для NVIDIA Device Plugin
export NVIDIA_DEVICE_PLUGIN_VERSION="v0.14.1"
export NVIDIA_NAMESPACE="gpu-operator"

# Переменные для GPU
export NVIDIA_DRIVER_MIN_VERSION="535.104.05"
export CUDA_MIN_VERSION="12.6.1"
export NVIDIA_CONTAINER_RUNTIME="nvidia"
export NVIDIA_VISIBLE_DEVICES="all"
export NVIDIA_DRIVER_CAPABILITIES="compute,utility"

# Цветовые коды для вывода
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# Переменные окружения для кластера
export CLUSTER_NAME="kind"
export NAMESPACE_PROD="prod"
export NAMESPACE_INGRESS="ingress-nginx"
export NAMESPACE_CERT_MANAGER="cert-manager"

# Переменные для хостов сервисов
export OLLAMA_HOST="ollama.prod.local"
export WEBUI_HOST="webui.prod.local"
export DASHBOARD_HOST="dashboard.prod.local"

# Добавляем переменные для IP-адресов сервисов
# Эти переменные будут использоваться в CoreDNS для резолвинга доменов
export OLLAMA_IP="127.0.0.1"
export WEBUI_IP="127.0.0.1"
export INGRESS_IP="127.0.0.1"

# Функция проверки ошибок
check_error() {
	if [ $? -ne 0 ]; then
		echo -e "${RED}$1${NC}"
		exit 1
	fi
}

# Функция ожидания готовности подов с повторными попытками
wait_for_pods() {
	local namespace=$1
	local selector=$2
	local timeout=${3:-600}  # Увеличенный таймаут по умолчанию до 600 секунд
	local max_attempts=${4:-3}  # Количество попыток по умолчанию
	local attempt=1

	while [ $attempt -le $max_attempts ]; do
		echo -e "${CYAN}Попытка $attempt из $max_attempts: Ожидание готовности подов в namespace $namespace...${NC}"
		
		if kubectl wait --for=condition=Ready pods -l $selector -n $namespace --timeout=${timeout}s; then
			echo -e "${GREEN}Поды успешно запущены!${NC}"
			return 0
		fi

		echo -e "${YELLOW}Попытка $attempt не удалась. Ожидание 30 секунд перед следующей попыткой...${NC}"
		sleep 30
		attempt=$((attempt + 1))
	done

	echo -e "${RED}Превышено количество попыток ожидания готовности подов${NC}"
	return 1
}

# Функция ожидания готовности deployment с повторными попытками
wait_for_deployment() {
	local namespace=$1
	local deployment=$2
	local timeout=${3:-300}
	local max_attempts=${4:-3}
	local attempt=1
	local interval=30

	while [ $attempt -le $max_attempts ]; do
		echo -e "${CYAN}Попытка $attempt из $max_attempts: Ожидание готовности deployment $deployment в namespace $namespace...${NC}"
		
		# Получение правильного селектора из deployment
		local selector=$(kubectl get deployment $deployment -n $namespace -o jsonpath='{.spec.selector.matchLabels}' 2>/dev/null | tr -d '{}' | sed 's/:/=/g')
		if [ -z "$selector" ]; then
			echo -e "${YELLOW}Не удалось получить селектор для deployment${NC}"
			selector="k8s-app=kube-dns"  # Фоллбэк для CoreDNS
		fi
		
		echo -e "${CYAN}Используется селектор: $selector${NC}"
		
		# Проверка статуса подов
		echo -e "${CYAN}Текущие поды:${NC}"
		kubectl get pods -n $namespace -l "$selector" -o wide
		
		# Проверка событий в namespace
		echo -e "${CYAN}Последние события в namespace $namespace:${NC}"
		kubectl get events -n $namespace --sort-by='.lastTimestamp' | tail -n 5
		
		# Ожидание готовности deployment
		if kubectl rollout status deployment/$deployment -n $namespace --timeout=${timeout}s; then
			# Дополнительная проверка готовности подов
			if kubectl wait --for=condition=Ready pods -l "$selector" -n $namespace --timeout=60s; then
				echo -e "${GREEN}Deployment $deployment успешно развернут!${NC}"
				return 0
			fi
		fi

		if [ $attempt -lt $max_attempts ]; then
			echo -e "${YELLOW}Попытка $attempt не удалась. Очистка и перезапуск...${NC}"
			
			# Удаление проблемных подов
			kubectl delete pods -n $namespace -l "$selector" --force --grace-period=0
			sleep 20
			
			# Перезапуск deployment
			kubectl rollout restart deployment/$deployment -n $namespace
			sleep $interval
		fi

		attempt=$((attempt + 1))
	done

	echo -e "${RED}Превышено количество попыток ожидания готовности deployment${NC}"
	return 1
}


# Функция ожидания готовности CRDs
wait_for_crds() {
	local timeout=60
	for crd in "$@"; do
		echo -e "${CYAN}Ожидание готовности CRD $crd...${NC}"
		kubectl wait --for=condition=established crd/$crd --timeout=${timeout}s
		check_error "Превышено время ожидания готовности CRD $crd"
	done
}

# Функция проверки GPU
check_gpu_available() {
    echo -e "${CYAN}Проверка GPU...${NC}"
    
    # Проверка nvidia-smi
    if ! nvidia-smi &> /dev/null; then
        echo -e "${RED}nvidia-smi не найден${NC}"
        return 1
    fi
    
    # Проверка версии драйвера
    local driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
    if [ -z "$driver_version" ]; then
        echo -e "${RED}Не удалось получить версию драйвера${NC}"
        return 1
    fi
    
    # Сравнение версии драйвера
    if ! awk -v v1="$driver_version" -v v2="$NVIDIA_DRIVER_MIN_VERSION" 'BEGIN{if (v1 >= v2) exit 0; else exit 1}'; then
        echo -e "${RED}Версия драйвера $driver_version ниже требуемой $NVIDIA_DRIVER_MIN_VERSION${NC}"
        return 1
    fi
    
    # Проверка NVIDIA Container Toolkit
    if ! dpkg -l | grep -q nvidia-container-toolkit; then
        echo -e "${RED}NVIDIA Container Toolkit не установлен${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Проверка GPU успешно пройдена${NC}"
    return 0
}

# Функция проверки использования Docker Desktop
is_docker_desktop() {
    # Check if Docker Desktop is being used in WSL2
    if grep -q "microsoft" /proc/version || grep -q "WSL" /proc/version; then
        # Check for Docker Desktop in docker info
        if docker info 2>/dev/null | grep -q "Docker Desktop"; then
            return 0  # True, Docker Desktop is being used
        fi
        
        # Check for Docker Desktop socket
        if [ -S "/mnt/wsl/docker-desktop/docker.sock" ] || [ -d "/mnt/wsl/docker-desktop" ]; then
            return 0  # True, Docker Desktop is being used
        fi
        
        # Check for Docker Desktop in Operating System field
        if docker info 2>/dev/null | grep -q "Operating System: Docker Desktop"; then
            return 0  # True, Docker Desktop is being used
        fi
    fi
    return 1  # False, standalone Docker or not in WSL2
}

# Функция настройки ulimit для решения проблемы "too many open files"
setup_ulimit() {
    echo -e "${CYAN}Проверка и настройка ulimit...${NC}"
    
    # Проверка текущего значения ulimit
    local current_ulimit=$(ulimit -n)
    echo -e "${YELLOW}Текущий лимит открытых файлов: ${current_ulimit}${NC}"
    
    # Увеличение лимита если он меньше рекомендуемого
    if [ "$current_ulimit" -lt 65536 ]; then
        echo -e "${YELLOW}Увеличение лимита открытых файлов (ulimit -n)...${NC}"
        ulimit -n 65536 || echo -e "${YELLOW}Не удалось увеличить ulimit, продолжаем...${NC}"
        echo -e "${YELLOW}Новый лимит открытых файлов: $(ulimit -n)${NC}"
    fi
    
    return 0
}



# Функция проверки существования кластера
check_cluster_exists() {
	local cluster_name=$1
	if kind get clusters 2>/dev/null | grep -q "^${cluster_name}$"; then
		return 0
	else
		return 1
	fi
}

# Функция проверки статуса Docker
check_docker_status() {
	# Check if Docker Desktop is being used in WSL2
	if is_docker_desktop; then
		echo -e "${YELLOW}Обнаружен Docker Desktop. Пропуск проверки статуса Docker...${NC}"
		return 0
	fi
	
	# Only check and start Docker for standalone Docker installations
	if ! systemctl is-active --quiet docker; then
		echo -e "${YELLOW}Docker не запущен. Для WSL с Docker Desktop это нормально.${NC}"
		echo -e "${YELLOW}Если вы используете стандартный Docker, запустите его вручную: sudo systemctl start docker${NC}"
		return 1
	fi
	return 0
}

# Функция проверки наличия необходимых инструментов
check_required_tools() {
    echo -e "${CYAN}Проверка наличия необходимых инструментов...${NC}"
    
    # Проверка Docker
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}Docker не установлен. Установите Docker перед продолжением.${NC}"
        return 1
    fi
    
    # Проверка KIND
    if ! command -v kind &>/dev/null; then
        echo -e "${RED}KIND не установлен.${NC}"
        
        # Автоматическая установка KIND, если установлен флаг AUTO_INSTALL
        if [[ "${AUTO_INSTALL}" == "true" ]]; then
            echo -e "${YELLOW}Автоматическая установка KIND...${NC}"
            
            # Установка KIND
            curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
            chmod +x ./kind
            sudo mv ./kind /usr/local/bin/kind
            
            # Проверка успешности установки
            if ! command -v kind &>/dev/null; then
                echo -e "${RED}Не удалось установить KIND. Установите KIND вручную перед продолжением.${NC}"
                return 1
            fi
            
            echo -e "${GREEN}KIND успешно установлен!${NC}"
        else
            echo -e "${YELLOW}Установите KIND перед продолжением.${NC}"
            return 1
        fi
    fi
    
    return 0
}

# Функция очистки Docker ресурсов
cleanup_docker_resources() {
	echo -e "${CYAN}Очистка Docker ресурсов...${NC}"
	
	# Остановка и удаление всех контейнеров
	if docker ps -aq &>/dev/null; then
		docker stop $(docker ps -aq) 2>/dev/null
		docker rm $(docker ps -aq) 2>/dev/null
	fi
	
	# Удаление неиспользуемых сетей
	docker network prune -f &>/dev/null
	
	# Очистка системы Docker
	docker system prune -f &>/dev/null
	
	echo -e "${GREEN}Docker ресурсы очищены${NC}"
	return 0
}

# Функция удаления существующего кластера
delete_cluster() {
	local cluster_name=$1
	local force_recreate=${2:-false}
	
	if check_cluster_exists "$cluster_name"; then
		echo -e "${YELLOW}Обнаружен существующий кластер ${cluster_name}. Удаляем...${NC}"
		
		if [ "$force_recreate" = "true" ]; then
			echo -e "${YELLOW}Режим полного пересоздания кластера активирован${NC}"
			
			# Удаление всех ресурсов кластера перед удалением самого кластера
			echo -e "${CYAN}Удаление всех ресурсов кластера...${NC}"
			
			# Получаем контекст кластера
			local context="kind-${cluster_name}"
			
			# Удаление всех namespace, кроме системных
			for ns in $(kubectl --context="$context" get namespaces -o name 2>/dev/null | grep -v "kube-system\|kube-public\|kube-node-lease\|default" || true); do
				echo -e "${CYAN}Удаление namespace ${ns}...${NC}"
				kubectl --context="$context" delete "$ns" --timeout=30s --wait=false 2>/dev/null || true
			done
			
			# Принудительное удаление всех подов в системных namespace
			for ns in kube-system kube-public default; do
				echo -e "${CYAN}Удаление подов в namespace ${ns}...${NC}"
				kubectl --context="$context" delete pods --all -n "$ns" --force --grace-period=0 2>/dev/null || true
			done
			
			# Ожидание некоторое время для завершения удаления ресурсов
			echo -e "${CYAN}Ожидание завершения удаления ресурсов...${NC}"
			sleep 5
		fi
		
		if ! kind delete cluster --name "$cluster_name"; then
			echo -e "${RED}Ошибка при удалении кластера ${cluster_name}${NC}"
			return 1
		fi
		echo -e "${GREEN}Кластер ${cluster_name} успешно удален${NC}"
		
		# Очистка после удаления кластера
		cleanup_docker_resources
		
		if [ "$force_recreate" = "true" ]; then
			# Дополнительная очистка Docker для режима полного пересоздания
			echo -e "${CYAN}Выполнение дополнительной очистки Docker...${NC}"
			
			# Удаление всех образов, связанных с kind
			docker images --filter=reference='*kind*' -q | xargs -r docker rmi -f 2>/dev/null || true
			
			# Принудительная очистка всех неиспользуемых объектов Docker
			docker system prune -af --volumes 2>/dev/null || true
			
			echo -e "${GREEN}Дополнительная очистка Docker завершена${NC}"
		fi
	fi
	return 0
}

# Функция подготовки системы к созданию кластера
prepare_system_for_cluster() {
	echo -e "${CYAN}Подготовка системы к созданию кластера...${NC}"
	
	# Проверка и запуск Docker
	if ! check_docker_status; then
		return 1
	fi
	
	# Очистка системы
	cleanup_docker_resources
	
	# Синхронизация с файловой системой
	sync
	
	echo -e "${GREEN}Система готова к созданию кластера${NC}"
	return 0
}

# Функция проверки и настройки cgroup
setup_cgroup_requirements() {
	echo -e "${CYAN}Проверка и настройка cgroup...${NC}"
	
	# Проверка WSL2 окружения
	local is_wsl=false
	if grep -q "microsoft" /proc/version || grep -q "WSL" /proc/version; then
		is_wsl=true
		echo -e "${YELLOW}Обнаружено WSL2 окружение${NC}"
	fi
	
	# Проверка версии cgroup
	local cgroup_version="v1"
	if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
		cgroup_version="v2"
		echo -e "${YELLOW}Обнаружена cgroup ${cgroup_version}${NC}"
	else
		echo -e "${YELLOW}Обнаружена cgroup ${cgroup_version}${NC}"
	fi
	
	# Специальная обработка для WSL2 с cgroup v2
	if [ "$is_wsl" = true ] && [ "$cgroup_version" = "v2" ]; then
		echo -e "${YELLOW}Настройка WSL2 с cgroup v2...${NC}"
		
		# Вывод информации о необходимости настройки .wslconfig в Windows
		echo -e "${YELLOW}ВНИМАНИЕ: Для корректной работы WSL2 с cgroup v2 необходимо настроить:${NC}"
		echo -e "${YELLOW}1. В Windows файл %UserProfile%\\.wslconfig:${NC}"
		echo -e "${YELLOW}   [wsl2]${NC}"
		echo -e "${YELLOW}   kernelCommandLine = cgroup_no_v1=all cgroup_enable=memory swapaccount=1${NC}"
		echo -e "${YELLOW}2. В WSL файл /etc/wsl.conf:${NC}"
		echo -e "${YELLOW}   [boot]${NC}"
		echo -e "${YELLOW}   systemd = true${NC}"
		
		# Проверка Docker Desktop
		if is_docker_desktop; then
			echo -e "${YELLOW}Обнаружен Docker Desktop. Пропуск настройки Docker daemon...${NC}"
		else
			# Настройка Docker daemon только для стандартного Docker
			if [ ! -f /etc/docker/daemon.json ] || ! grep -q "systemd" /etc/docker/daemon.json; then
				echo -e "${YELLOW}Настройка Docker daemon внутри WSL2 для работы с cgroup v2...${NC}"
				sudo mkdir -p /etc/docker
				cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  }
}
EOF
			fi
		fi
	fi
	
	# Проверка и загрузка необходимых модулей ядра
	echo -e "${YELLOW}Загрузка модуля ядра overlay...${NC}"
	if ! lsmod | grep -q "^overlay"; then
		sudo modprobe overlay || true
	fi
	
	echo -e "${YELLOW}Загрузка модуля ядра br_netfilter...${NC}"
	if ! lsmod | grep -q "^br_netfilter"; then
		sudo modprobe br_netfilter || true
	fi
	
	# Настройка параметров сети
	echo -e "${CYAN}Настройка сетевых параметров...${NC}"
	sudo sysctl -w net.bridge.bridge-nf-call-iptables=1 >/dev/null || true
	sudo sysctl -w net.bridge.bridge-nf-call-ip6tables=1 >/dev/null || true
	sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null || true
	
	# Для WSL2 дополнительно настраиваем лимиты памяти
	if [ "$is_wsl" = true ]; then
		echo -e "${YELLOW}Настройка лимитов памяти для WSL2...${NC}"
		sudo sysctl -w vm.max_map_count=262144 >/dev/null || true
		
		# Сохранение настроек для будущих запусков
		if [ ! -f /etc/sysctl.d/99-wsl.conf ]; then
			echo "vm.max_map_count=262144" | sudo tee /etc/sysctl.d/99-wsl.conf >/dev/null
		fi
	fi
	
	# Настройка ulimit
	setup_ulimit
	
	return 0
}

# Функция подготовки системы к созданию кластера
prepare_system_for_cluster() {
    echo -e "${CYAN}Подготовка системы к созданию кластера...${NC}"
    
    # Проверка наличия необходимых инструментов
    if ! check_required_tools; then
        return 1
    fi
    
    # Проверка и настройка cgroup
    if ! setup_cgroup_requirements; then
        return 1
    fi
    
    # Проверка Docker cgroup driver
    echo -e "${CYAN}Проверка Docker cgroup driver...${NC}"
    local cgroup_driver=$(docker info 2>/dev/null | grep "Cgroup Driver" | awk '{print $3}')
    echo -e "${YELLOW}Текущий Docker cgroup driver: ${cgroup_driver}${NC}"
    
    # Проверка Docker Cgroup Version
    local cgroup_version=$(docker info 2>/dev/null | grep "Cgroup Version" | awk '{print $3}')
    if [ -n "$cgroup_version" ]; then
        echo -e "${YELLOW}Текущая Docker Cgroup Version: ${cgroup_version}${NC}"
    fi
    
    # Синхронизация с файловой системой
    sync
    
    echo -e "${GREEN}Система готова к созданию кластера${NC}"
    return 0
}

# Если скрипт запущен напрямую, выводим информацию о переменных
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	echo -e "${CYAN}Текущие настройки окружения:${NC}"
	echo -e "${YELLOW}Кластер:${NC} $CLUSTER_NAME"
	echo -e "${YELLOW}Namespace Production:${NC} $NAMESPACE_PROD"
	echo -e "${YELLOW}Namespace Ingress:${NC} $NAMESPACE_INGRESS"
	echo -e "${YELLOW}Namespace Cert Manager:${NC} $NAMESPACE_CERT_MANAGER"
	echo -e "\n${YELLOW}Хосты сервисов:${NC}"
	echo -e "Ollama API: https://$OLLAMA_HOST"
	echo -e "Open WebUI: https://$WEBUI_HOST"

	if check_gpu_available; then
		echo -e "\n${GREEN}GPU обнаружен${NC}"
	else
		echo -e "\n${YELLOW}GPU не обнаружен${NC}"
	fi
fi