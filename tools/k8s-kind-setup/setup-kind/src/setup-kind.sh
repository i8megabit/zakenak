#!/usr/bin/bash
#  _  _____ ____  
# | |/ / _ \___ \ 
# | ' / (_) |__) |
# | . \> _ </ __/ 
# |_|\_\___/_____|
#            by @eberil

# Загрузка общих переменных и баннеров
source "$(dirname "${BASH_SOURCE[0]}")/../../../env/src/env.sh"
source "${SCRIPTS_ASCII_BANNERS_PATH}"

# Отображение баннера при старте
k8s_banner
echo ""

echo -e "${YELLOW}Начинаем установку кластера Kind...${NC}"


# Определение WSL2 окружения и наличия NVIDIA GPU
check_wsl_gpu() {
	if grep -q microsoft /proc/version && command -v nvidia-smi >/dev/null 2>&1; then
		echo true
	else
		echo false
	fi
}

# Проверка установки бинарных компонентов
check_binaries() {
	echo -e "${CYAN}Проверка установленных компонентов...${NC}"
	local required_bins=("kind" "kubectl" "helm")
	for bin in "${required_bins[@]}"; do
		if ! command -v "$bin" &> /dev/null; then
			echo -e "${RED}Ошибка: $bin не установлен. Запустите setup-bins.sh${NC}"
			exit 1
		fi
	done
}

# Генерация конфигурации Kind в зависимости от окружения
generate_kind_config() {
	local config_file="${SCRIPT_DIR}/kind-config.yaml"
	local is_wsl_gpu=$(check_wsl_gpu)

	if [ "$is_wsl_gpu" = true ]; then
		echo -e "${CYAN}Обнаружено WSL2 окружение с NVIDIA GPU. Применяем соответствующую конфигурацию...${NC}"
		cat > "$config_file" << EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kind
nodes:
- role: control-plane
  extraMounts:
  - hostPath: /usr/lib/wsl/lib
    containerPath: /usr/lib/wsl/lib
  - hostPath: /usr/bin/nvidia-smi
    containerPath: /usr/bin/nvidia-smi
  - hostPath: /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1
    containerPath: /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
    privileged_without_host_devices = false
    runtime_engine = "nvidia-container-runtime"
    runtime_root = ""
    runtime_type = "io.containerd.runc.v2"
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia.options]
      SystemdCgroup = true
EOF
	else
		echo -e "${CYAN}Применяем стандартную конфигурацию...${NC}"
		cat > "$config_file" << EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kind
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
EOF
	fi
}

# Создание кластера
setup_kind_cluster() {
	# Подготовка системы к созданию кластера
	if ! prepare_system_for_cluster; then
		echo -e "${RED}Ошибка при подготовке системы${NC}"
		exit 1
	fi

	# Удаление существующего кластера
	if ! delete_cluster "${CLUSTER_NAME}"; then
		echo -e "${RED}Ошибка при попытке удаления существующего кластера${NC}"
		exit 1
	fi

	# Генерация конфигурации перед созданием кластера
	generate_kind_config
	
	echo -e "${CYAN}Создание нового кластера ${CLUSTER_NAME}...${NC}"
	if ! KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster \
		--name "${CLUSTER_NAME}" \
		--config "${SCRIPT_DIR}/kind-config.yaml" \
		--wait 5m; then
		echo -e "${RED}Ошибка при создании кластера${NC}"
		exit 1
	fi
	
	# Ожидание готовности API сервера с увеличенным таймаутом
	echo -e "${CYAN}Ожидание готовности API сервера...${NC}"
	timeout=300
	while ! kubectl cluster-info &>/dev/null; do
		if [ $timeout -le 0 ]; then
			echo -e "${RED}Превышено время ожидания готовности API сервера${NC}"
			exit 1
		fi
		echo -e "${YELLOW}Ожидание запуска кластера... (осталось ${timeout}с)${NC}"
		sleep 5
		timeout=$((timeout - 5))
	done
	
	# Проверка статуса узлов кластера
	echo -e "${CYAN}Проверка статуса узлов кластера...${NC}"
	if ! kubectl wait --for=condition=ready nodes --all --timeout=5m; then
		echo -e "${RED}Не все узлы кластера готовы${NC}"
		exit 1
	fi
	
	# Создание необходимых namespace
	echo -e "${CYAN}Создание namespace...${NC}"
	for ns in "${NAMESPACE_PROD}" "${NAMESPACE_INGRESS}" "${NAMESPACE_CERT_MANAGER}"; do
		if ! kubectl create namespace "$ns" 2>/dev/null; then
			echo -e "${YELLOW}Namespace $ns уже существует${NC}"
		fi
	done
	
	echo -e "${GREEN}Кластер ${CLUSTER_NAME} успешно создан${NC}"
}

# Установка NVIDIA Device Plugin
install_nvidia_plugin() {
	if [ "$(check_wsl_gpu)" = true ]; then
		echo -e "${CYAN}Установка NVIDIA Device Plugin...${NC}"
		kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.1/nvidia-device-plugin.yml
		check_error "Ошибка установки NVIDIA Device Plugin"
	else
		echo -e "${YELLOW}Пропуск установки NVIDIA Device Plugin (GPU не обнаружен)${NC}"
	fi
}

# Основная функция
main() {
	check_binaries
	setup_kind_cluster
	install_nvidia_plugin
	
	echo -e "\n"
	success_banner
	echo -e "\n${GREEN}Установка кластера Kind успешно завершена!${NC}"
}

main "$@"