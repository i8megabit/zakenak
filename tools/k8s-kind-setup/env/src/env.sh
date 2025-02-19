#!/usr/bin/bash
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

# Функция проверки наличия GPU
check_gpu_available() {
	if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
		return 0
	else
		return 1
	fi
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
	if ! systemctl is-active --quiet docker; then
		echo -e "${YELLOW}Docker не запущен. Запускаем Docker...${NC}"
		sudo systemctl start docker
		sleep 5
	fi
	
	if ! systemctl is-active --quiet docker; then
		echo -e "${RED}Не удалось запустить Docker${NC}"
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
        echo -e "${RED}KIND не установлен. Установите KIND перед продолжением.${NC}"
        return 1
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
	if check_cluster_exists "$cluster_name"; then
		echo -e "${YELLOW}Обнаружен существующий кластер ${cluster_name}. Удаляем...${NC}"
		if ! kind delete cluster --name "$cluster_name"; then
			echo -e "${RED}Ошибка при удалении кластера ${cluster_name}${NC}"
			return 1
		fi
		echo -e "${GREEN}Кластер ${cluster_name} успешно удален${NC}"
		
		# Очистка после удаления кластера
		cleanup_docker_resources
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

# Функция проверки и настройки cgroup v2
setup_cgroup_requirements() {
	echo -e "${CYAN}Проверка и настройка cgroup...${NC}"
	
	# Проверка использования cgroup v2
	if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
		echo -e "${YELLOW}Обнаружена cgroup v2${NC}"
		
		# Проверка и настройка параметров ядра
		if ! grep -q "systemd.unified_cgroup_hierarchy=1" /proc/cmdline; then
			echo -e "${YELLOW}Добавление параметров загрузки для cgroup v2...${NC}"
			if [ -f /etc/default/grub ]; then
				sudo sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=1 /' /etc/default/grub
				sudo update-grub
				echo -e "${YELLOW}Требуется перезагрузка системы для применения изменений${NC}"
				return 1
			fi
		fi
	fi
	
	# Проверка и включение необходимых модулей ядра
	local required_modules="overlay br_netfilter"
	for module in $required_modules; do
		if ! lsmod | grep -q "^$module"; then
			echo -e "${YELLOW}Загрузка модуля ядра $module...${NC}"
			sudo modprobe $module
		fi
	done
	
	# Настройка параметров сети
	local sysctl_params="
		net.bridge.bridge-nf-call-iptables=1
		net.bridge.bridge-nf-call-ip6tables=1
		net.ipv4.ip_forward=1
	"
	
	echo -e "${CYAN}Настройка сетевых параметров...${NC}"
	for param in $sysctl_params; do
		sudo sysctl -w $param >/dev/null
	done
	
	return 0
}

# Функция проверки и настройки Docker для работы с KIND
setup_docker_for_kind() {
	echo -e "${CYAN}Настройка Docker для работы с KIND...${NC}"
	
	# Проверка наличия конфигурации daemon.json
	local daemon_json="/etc/docker/daemon.json"
	if [ ! -f "$daemon_json" ]; then
		echo -e "${YELLOW}Создание конфигурации Docker...${NC}"
		sudo mkdir -p /etc/docker
		echo '{
			"exec-opts": ["native.cgroupdriver=systemd"],
			"log-driver": "json-file",
			"log-opts": {
				"max-size": "100m"
			},
			"storage-driver": "overlay2"
		}' | sudo tee $daemon_json > /dev/null
		
		# Перезапуск Docker для применения изменений
		echo -e "${YELLOW}Перезапуск Docker...${NC}"
		sudo systemctl restart docker
		sleep 5
	fi
	
	return 0
}

# Обновленная функция подготовки системы к созданию кластера
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
	
	# Проверка и запуск Docker
	if ! check_docker_status; then
		return 1
	fi
	
	# Настройка Docker для работы с KIND
	if ! setup_docker_for_kind; then
		return 1
	fi
	
	# Очистка системы
	cleanup_docker_resources
	
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