#!/usr/bin/bash

# Загрузка переменных окружения
source "$(dirname "${BASH_SOURCE[0]}")/../../../env/src/env.sh"

echo -e "${CYAN}Настройка кластера KIND...${NC}"

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

# Проверка и настройка WSL2
if grep -q "microsoft" /proc/version; then
	echo -e "${CYAN}Обнаружено WSL2 окружение. Применяем специальные настройки...${NC}"
	# Настройка лимитов памяти для WSL2
	if [ ! -f /etc/sysctl.d/99-wsl.conf ]; then
		echo "vm.max_map_count=262144" | sudo tee /etc/sysctl.d/99-wsl.conf
		sudo sysctl -p /etc/sysctl.d/99-wsl.conf
	fi
fi

# Создание нового кластера с увеличенным таймаутом и специальной конфигурацией
echo -e "${CYAN}Создание нового кластера ${CLUSTER_NAME}...${NC}"
if ! kind create cluster --name "${CLUSTER_NAME}" \
	--config="$(dirname "${BASH_SOURCE[0]}")/kind-config.yaml" \
	--wait 10m; then
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
	if ! kubectl apply -f "https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/${NVIDIA_DEVICE_PLUGIN_VERSION}/nvidia-device-plugin.yml" -n "${NVIDIA_NAMESPACE}"; then
		echo -e "${RED}Ошибка установки NVIDIA Device Plugin${NC}"
		exit 1
	fi
	
	# Ожидание готовности DaemonSet
	echo -e "${CYAN}Ожидание готовности NVIDIA Device Plugin...${NC}"
	if ! kubectl rollout status daemonset/nvidia-device-plugin-daemonset -n "${NVIDIA_NAMESPACE}" --timeout=120s; then
		echo -e "${RED}Ошибка при ожидании готовности NVIDIA Device Plugin${NC}"
		exit 1
	fi
	
	echo -e "${GREEN}NVIDIA Device Plugin успешно установлен${NC}"
else
	echo -e "${YELLOW}GPU не обнаружен, пропуск установки NVIDIA Device Plugin${NC}"
fi

echo -e "${GREEN}Кластер KIND успешно настроен!${NC}"
