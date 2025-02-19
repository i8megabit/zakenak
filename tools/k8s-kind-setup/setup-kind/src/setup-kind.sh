#!/usr/bin/bash
#  _  _____ ____  
# | |/ / _ \___ \ 
# | ' / (_) |__) |
# | . \> _ </ __/ 
# |_|\_\___/_____|
#            by @eberil

# Определение пути к директории скрипта и корню репозитория
export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export TOOLS_DIR="${BASE_DIR}/tools/k8s-kind-setup"
export SCRIPTS_ENV_PATH="${TOOLS_DIR}/env/src/env.sh"

# Загрузка общих переменных и баннеров
source "${SCRIPTS_ENV_PATH}"
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
	echo -e "${CYAN}Проверка существующего кластера...${NC}"
	if kind get clusters 2>/dev/null | grep -q "^kind$"; then
		echo -e "${YELLOW}Обнаружен существующий кластер 'kind'. Удаляем...${NC}"
		kind delete cluster
		check_error "Не удалось удалить существующий кластер"
		sleep 5
	fi
	
	# Генерация конфигурации перед созданием кластера
	generate_kind_config
	
	echo -e "${CYAN}Создание нового кластера Kind...${NC}"
	kind create cluster --config "${SCRIPT_DIR}/kind-config.yaml"
	check_error "Не удалось создать кластер Kind"
	
	# Ожидание готовности узлов
	echo -e "${CYAN}Ожидание готовности узлов кластера...${NC}"
	kubectl wait --for=condition=Ready nodes --all --timeout=300s
	check_error "Узлы кластера не готовы"
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