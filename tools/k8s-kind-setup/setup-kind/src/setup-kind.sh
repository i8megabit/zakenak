#!/usr/bin/bash
#  _  _____ ____  
# | |/ / _ \___ \ 
# | ' / (_) |__) |
# | . \> _ </ __/ 
# |_|\_\___/_____|
#            by @eberil

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Загрузка общих переменных и баннеров
source "${REPO_ROOT}/tools/k8s-kind-setup/env.sh"
source "${REPO_ROOT}/tools/k8s-kind-setup/ascii_banners.sh"

# Отображение баннера при старте
k8s_banner
echo ""

echo -e "${YELLOW}Начинаем установку кластера Kind...${NC}"

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

# Создание кластера
setup_kind_cluster() {
	echo -e "${CYAN}Проверка существующего кластера...${NC}"
	if kind get clusters 2>/dev/null | grep -q "^kind$"; then
		echo -e "${YELLOW}Обнаружен существующий кластер 'kind'. Удаляем...${NC}"
		kind delete cluster
		check_error "Не удалось удалить существующий кластер"
		sleep 5
	fi
	
	echo -e "${CYAN}Создание нового кластера Kind...${NC}"
	kind create cluster --config "${SCRIPT_DIR}/kubeconfig.yaml"
	check_error "Не удалось создать кластер Kind"
	
	# Ожидание готовности узлов
	echo -e "${CYAN}Ожидание готовности узлов кластера...${NC}"
	kubectl wait --for=condition=Ready nodes --all --timeout=300s
	check_error "Узлы кластера не готовы"
}

# Установка NVIDIA Device Plugin
install_nvidia_plugin() {
	echo -e "${CYAN}Установка NVIDIA Device Plugin...${NC}"
	kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.1/nvidia-device-plugin.yml
	check_error "Ошибка установки NVIDIA Device Plugin"
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