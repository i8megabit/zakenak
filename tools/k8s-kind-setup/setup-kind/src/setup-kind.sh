#!/usr/bin/bash

# Загрузка переменных окружения
export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export TOOLS_DIR="${BASE_DIR}/tools/k8s-kind-setup"
export SCRIPTS_ENV_PATH="${TOOLS_DIR}/env/src/env.sh"

# Add Docker Desktop detection function
is_docker_desktop() {
    # Check if Docker Desktop is being used in WSL2
    if grep -q "microsoft" /proc/version || grep -q "WSL" /proc/version; then
        if docker info 2>/dev/null | grep -q "Docker Desktop"; then
            return 0  # True, Docker Desktop is being used
        fi
    fi
    return 1  # False, standalone Docker or not in WSL2
}

# Проверка, был ли передан флаг AUTO_INSTALL из родительского скрипта
if [[ -z "${AUTO_INSTALL}" ]]; then
    # Если переменная не определена, устанавливаем значение по умолчанию
    export AUTO_INSTALL=false
fi

# Проверка, был ли передан флаг FORCE_RECREATE из родительского скрипта
if [[ -z "${FORCE_RECREATE}" ]]; then
    # Если переменная не определена, устанавливаем значение по умолчанию
    export FORCE_RECREATE=false
fi

echo -e "${CYAN}Настройка кластера KIND...${NC}"
setup_ulimit

# Подготовка системы к созданию кластера
if ! prepare_system_for_cluster; then
    echo -e "${RED}Ошибка при подготовке системы${NC}"
    exit 1
fi

# Удаление существующего кластера
if ! delete_cluster "${CLUSTER_NAME}" "${FORCE_RECREATE}"; then
    echo -e "${RED}Ошибка при попытке удаления существующего кластера${NC}"
    exit 1
fi

# Проверка и настройка WSL2
IS_WSL=false
USING_DOCKER_DESKTOP=false
CONFIG_FILE="${TOOLS_DIR}/kind/config/kind-config-gpu.yml"

if grep -q "microsoft" /proc/version || grep -q "WSL" /proc/version; then
    IS_WSL=true
    echo -e "${CYAN}Обнаружено WSL2 окружение. Применяем специальные настройки...${NC}"
    
    # Определение режима сети WSL2
    NETWORK_MODE="NAT"  # По умолчанию NAT
    if [ "$IS_WSL" = true ]; then
        if command -v detect_wsl_network_mode &>/dev/null; then
            NETWORK_MODE=$(detect_wsl_network_mode)
        else
            # Проверка наличия файла .wslconfig в Windows
            WSL_CONFIG_PATH="/mnt/c/Users/$USER/.wslconfig"
            if [ -f "$WSL_CONFIG_PATH" ]; then
                if grep -q "networkingMode=mirrored" "$WSL_CONFIG_PATH"; then
                    NETWORK_MODE="mirrored"
                fi
            fi
        fi
        echo -e "${CYAN}Обнаружен режим сети WSL2: ${NETWORK_MODE}${NC}"
    fi
    
    # Проверка Docker Desktop
    if is_docker_desktop; then
        USING_DOCKER_DESKTOP=true
        echo -e "${CYAN}Обнаружен Docker Desktop. Используем специальные настройки...${NC}"
        
        # Дополнительная диагностика
        echo -e "${YELLOW}Диагностика Docker Desktop:${NC}"
        docker info | grep -E "Docker Desktop|Operating System|Cgroup"
    else
        echo -e "${YELLOW}Docker Desktop не обнаружен, используется стандартный Docker${NC}"
        docker info | grep -E "Operating System|Cgroup"
    fi
    
    # Настройка лимитов памяти для WSL2
    if [ ! -f /etc/sysctl.d/99-wsl.conf ]; then
        echo "vm.max_map_count=262144" | sudo tee /etc/sysctl.d/99-wsl.conf
        sudo sysctl -p /etc/sysctl.d/99-wsl.conf
    fi
    
    # Создаем временный файл конфигурации с настройками для WSL2
    TMP_CONFIG_FILE="/tmp/kind-config-wsl.yml"

if [ "$USING_DOCKER_DESKTOP" = true ]; then
    echo -e "${CYAN}Создание конфигурации для Docker Desktop с двумя узлами...${NC}"
    cat <<EOF > "$TMP_CONFIG_FILE"
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true,nvidia.com/gpu=true"
        feature-gates: "DevicePlugins=true"
    skipPhases:
      - preflight
  - |
    kind: ClusterConfiguration
    apiServer:
      extraArgs:
        feature-gates: "DevicePlugins=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
  kubeadmConfigPatches:
  - |
    kind: JoinConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "nvidia.com/gpu=true"
        feature-gates: "DevicePlugins=true"
    skipPhases:
      - preflight
EOF
else
    # Стандартная конфигурация для WSL2 без Docker Desktop
    cat <<EOF > "$TMP_CONFIG_FILE"
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
        feature-gates: "DevicePlugins=true"
    skipPhases:
      - preflight
  - |
    kind: ClusterConfiguration
    apiServer:
      extraArgs:
        feature-gates: "DevicePlugins=true"
  extraMounts:
  - hostPath: /usr/lib/wsl/lib
    containerPath: /usr/lib/wsl/lib
  - hostPath: /usr/bin/nvidia-smi
    containerPath: /usr/bin/nvidia-smi
  - hostPath: /usr/lib/x86_64-linux-gnu
    containerPath: /usr/lib/x86_64-linux-gnu
  - hostPath: /usr/local/cuda/lib64
    containerPath: /usr/local/cuda/lib64
    readOnly: true
    propagation: None
  - hostPath: /usr/local/cuda/include
    containerPath: /usr/local/cuda/include
    readOnly: true
    propagation: None
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
  kubeadmConfigPatches:
  - |
    kind: JoinConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "nvidia.com/gpu=true"
        feature-gates: "DevicePlugins=true"
    skipPhases:
      - preflight
  extraMounts:
  - hostPath: /usr/lib/wsl/lib
    containerPath: /usr/lib/wsl/lib
  - hostPath: /usr/bin/nvidia-smi
    containerPath: /usr/bin/nvidia-smi
  - hostPath: /usr/lib/x86_64-linux-gnu
    containerPath: /usr/lib/x86_64-linux-gnu
  - hostPath: /usr/local/cuda/lib64
    containerPath: /usr/local/cuda/lib64
    readOnly: true
    propagation: None
  - hostPath: /usr/local/cuda/include
    containerPath: /usr/local/cuda/include
    readOnly: true
    propagation: None
EOF
fi
    CONFIG_FILE="$TMP_CONFIG_FILE"
fi

# Создание нового кластера с увеличенным таймаутом и специальной конфигурацией
echo -e "${CYAN}Создание нового кластера ${CLUSTER_NAME}...${NC}"

# Установка переменных окружения для KIND
export DOCKER_HOST=unix:///var/run/docker.sock

# Настройка специальных флагов для KIND в зависимости от окружения
if [ "$USING_DOCKER_DESKTOP" = true ]; then
    echo -e "${CYAN}Настройка специальных параметров для Docker Desktop...${NC}"
    export KIND_EXPERIMENTAL_CONTAINERD_SNAPSHOTTER="fuse-overlayfs"
    KIND_FLAGS="--wait 5m"
else
    KIND_FLAGS="--wait 5m"
fi

# Вывод информации о конфигурации перед созданием кластера
echo -e "${CYAN}Используемая конфигурация: ${CONFIG_FILE}${NC}"
echo -e "${CYAN}Флаги KIND: ${KIND_FLAGS}${NC}"

# Создание кластера с увеличенным таймаутом и дополнительными флагами
if ! kind create cluster --name "${CLUSTER_NAME}" \
    --config="$CONFIG_FILE" \
    ${KIND_FLAGS}; then
    
# Дополнительная настройка для режима mirrored
if [ "$IS_WSL" = true ] && [ "$NETWORK_MODE" = "mirrored" ]; then
    echo -e "${CYAN}Применение специальных настроек для режима mirrored...${NC}"
    
    # Получение IP-адреса хоста Windows
    HOST_IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -n 1)
    if [ -z "$HOST_IP" ] || [ "$HOST_IP" = "127.0.0.1" ]; then
        # Альтернативный способ получения IP хоста
        HOST_IP=$(ip route | grep default | awk '{print $3}')
    fi
    
    echo -e "${CYAN}IP-адрес хоста Windows: ${HOST_IP}${NC}"
    
    # Проверка доступности API сервера через IP хоста
    echo -e "${CYAN}Проверка доступности API сервера через IP хоста...${NC}"
    if curl -k -s "https://${HOST_IP}:6443" &>/dev/null; then
        echo -e "${GREEN}API сервер доступен через IP хоста${NC}"
    else
        echo -e "${YELLOW}API сервер недоступен через IP хоста. Это может быть нормально на данном этапе.${NC}"
    fi
fi
    echo -e "${RED}Ошибка при создании кластера${NC}"
    
    # Дополнительная диагностика при ошибке
    echo -e "${YELLOW}Диагностическая информация:${NC}"
    echo -e "${YELLOW}Docker info:${NC}"
    docker info | grep -E "Cgroup|Version|Operating System"
    
    echo -e "${YELLOW}Проверка cgroup:${NC}"
    mount | grep cgroup
    
    echo -e "${YELLOW}Проверка systemd:${NC}"
    systemctl is-system-running || echo "systemd не запущен или недоступен"
    
    # Запуск тестового скрипта для проверки
    echo -e "${YELLOW}Запуск тестового скрипта для проверки...${NC}"
    "${TOOLS_DIR}/test-kind-wsl.sh" || true
    
    echo -e "${RED}Рекомендации:${NC}"
    echo -e "1. Убедитесь, что в Windows настроен файл %UserProfile%\\.wslconfig с параметрами:"
    echo -e "   [boot]"
    echo -e "   systemd=true"
    echo -e "   [wsl2]"
    echo -e "   kernelCommandLine = cgroup_no_v1=all cgroup_enable=memory swapaccount=1"
    echo -e "2. Перезапустите WSL командой 'wsl --shutdown' в PowerShell"
    echo -e "3. Перезапустите Docker Desktop"
    echo -e "4. Попробуйте запустить тестовый скрипт: ${TOOLS_DIR}/test-kind-wsl.sh"
    
    exit 1
fi

# Дополнительная настройка для режима mirrored
if [ "$IS_WSL" = true ] && [ "$NETWORK_MODE" = "mirrored" ]; then
    echo -e "${CYAN}Применение специальных настроек для режима mirrored...${NC}"
    
    # Получение IP-адреса хоста Windows
    HOST_IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -n 1)
    if [ -z "$HOST_IP" ] || [ "$HOST_IP" = "127.0.0.1" ]; then
        # Альтернативный способ получения IP хоста
        HOST_IP=$(ip route | grep default | awk '{print $3}')
    fi
    
    echo -e "${CYAN}IP-адрес хоста Windows: ${HOST_IP}${NC}"
    
    # Проверка доступности API сервера через IP хоста
    echo -e "${CYAN}Проверка доступности API сервера через IP хоста...${NC}"
    if curl -k -s "https://${HOST_IP}:6443" &>/dev/null; then
        echo -e "${GREEN}API сервер доступен через IP хоста${NC}"
    else
        echo -e "${YELLOW}API сервер недоступен через IP хоста. Это может быть нормально на данном этапе.${NC}"
    fi
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

# Создание namespace
echo -e "${CYAN}Создание namespace...${NC}"
kubectl create namespace "${NAMESPACE_PROD}" 2>/dev/null || true
kubectl create namespace "${NAMESPACE_INGRESS}" 2>/dev/null || true
kubectl create namespace "${NAMESPACE_CERT_MANAGER}" 2>/dev/null || true

# Установка NVIDIA Device Plugin если доступен GPU
if check_gpu_available; then
    echo -e "${CYAN}Обнаружен GPU. Установка NVIDIA Device Plugin...${NC}"
    
    # Создание namespace для NVIDIA
    kubectl create namespace "${NVIDIA_NAMESPACE}" 2>/dev/null || true
    
    echo -e "${CYAN}Применение манифеста NVIDIA Device Plugin...${NC}"
    # Delete existing DaemonSet if it exists to ensure the new configuration is applied
    kubectl delete daemonset nvidia-device-plugin-daemonset -n kube-system --ignore-not-found=true
    # Use our custom manifest instead of the one from GitHub
    if ! kubectl apply -f "${TOOLS_DIR}/nvidia-device-plugin-custom.yml"; then
        echo -e "${RED}Ошибка установки NVIDIA Device Plugin${NC}"
        exit 1
    fi
    
    # Ожидание готовности DaemonSet
    echo -e "${CYAN}Ожидание готовности NVIDIA Device Plugin...${NC}"

    # Get the namespace where the daemonset is deployed
    PLUGIN_NAMESPACE=$(kubectl get daemonset -A | grep nvidia-device-plugin-daemonset | awk '{print $1}')
    if [[ -z "$PLUGIN_NAMESPACE" ]]; then
        PLUGIN_NAMESPACE="kube-system"  # Default to kube-system if not found
        echo -e "${YELLOW}DaemonSet не найден, используем namespace по умолчанию: ${PLUGIN_NAMESPACE}${NC}"
    else
        echo -e "${CYAN}DaemonSet найден в namespace: ${PLUGIN_NAMESPACE}${NC}"
    fi

    if ! kubectl rollout status daemonset/nvidia-device-plugin-daemonset -n "${PLUGIN_NAMESPACE}" --timeout=120s; then
        echo -e "${RED}Ошибка при ожидании готовности NVIDIA Device Plugin${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}NVIDIA Device Plugin успешно установлен${NC}"
else
    echo -e "${YELLOW}GPU не обнаружен, пропуск установки NVIDIA Device Plugin${NC}"
fi

echo -e "${GREEN}Кластер KIND успешно настроен!${NC}"