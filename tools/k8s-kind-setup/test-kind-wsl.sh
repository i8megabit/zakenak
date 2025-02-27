#!/usr/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Тестирование создания кластера KIND в WSL2...${NC}"

# Проверка WSL2
if ! grep -q "microsoft" /proc/version && ! grep -q "WSL" /proc/version; then
    echo -e "${RED}Этот скрипт предназначен только для WSL2${NC}"
    exit 1
fi

echo -e "${CYAN}Обнаружено WSL2 окружение${NC}"

# Функция проверки Docker Desktop
is_docker_desktop() {
    if docker info 2>/dev/null | grep -q "Docker Desktop"; then
        return 0  # True, Docker Desktop is being used
    fi
    return 1  # False, standalone Docker
}

# Проверка Docker Desktop
if is_docker_desktop; then
    echo -e "${GREEN}Обнаружен Docker Desktop${NC}"
else
    echo -e "${YELLOW}Docker Desktop не обнаружен, используется стандартный Docker${NC}"
fi

# Проверка cgroup v2
if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
    echo -e "${CYAN}Обнаружена cgroup v2${NC}"
else
    echo -e "${YELLOW}Обнаружена cgroup v1${NC}"
fi

# Проверка systemd
if systemctl is-system-running &>/dev/null; then
    echo -e "${GREEN}systemd активен${NC}"
else
    echo -e "${YELLOW}systemd не активен${NC}"
    echo -e "${YELLOW}Рекомендуется добавить в /etc/wsl.conf:${NC}"
    echo -e "${YELLOW}[boot]${NC}"
    echo -e "${YELLOW}systemd=true${NC}"
fi

# Проверка Docker cgroup driver
DOCKER_CGROUP_DRIVER=$(docker info 2>/dev/null | grep "Cgroup Driver" | awk '{print $3}')
echo -e "${CYAN}Docker cgroup driver: ${DOCKER_CGROUP_DRIVER}${NC}"

# Удаление существующего кластера
echo -e "${CYAN}Удаление существующего кластера kind (если есть)...${NC}"
kind delete cluster --name test-wsl 2>/dev/null || true

# Создание временного файла конфигурации
echo -e "${CYAN}Создание конфигурации для KIND...${NC}"
TMP_CONFIG_FILE="/tmp/kind-config-test.yml"

# Добавляем специальные настройки для Docker Desktop
if is_docker_desktop; then
    echo -e "${CYAN}Добавление специальных настроек для Docker Desktop в конфигурацию...${NC}"
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
EOF
else
    # Стандартная конфигурация
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
EOF
fi

# Создание кластера
echo -e "${CYAN}Создание тестового кластера KIND...${NC}"

# Для Docker Desktop добавляем специальные флаги
if is_docker_desktop; then
    export KIND_EXPERIMENTAL_CONTAINERD_SNAPSHOTTER="fuse-overlayfs"
    KIND_FLAGS="--wait 5m"
else
    KIND_FLAGS="--wait 5m"
fi

if kind create cluster --name test-wsl --config="$TMP_CONFIG_FILE" ${KIND_FLAGS}; then
    echo -e "${GREEN}Кластер KIND успешно создан!${NC}"
    
    # Проверка доступа к кластеру
    if kubectl cluster-info; then
        echo -e "${GREEN}Доступ к кластеру Kubernetes успешно настроен${NC}"
        echo -e "${GREEN}Тест успешно пройден!${NC}"
        exit 0
    else
        echo -e "${RED}Ошибка: Не удалось получить доступ к кластеру${NC}"
        exit 1
    fi
else
    echo -e "${RED}Ошибка при создании кластера KIND${NC}"
    exit 1
fi