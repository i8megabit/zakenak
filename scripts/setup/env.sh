#!/bin/bash

# Цвета для вывода
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export CYAN='\033[0;36m'
export NC='\033[0m'

# Определение пути к директории скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"


# Установка прав на исполнение для discover.sh
chmod +x "${SCRIPT_DIR}/discover.sh"

# Загрузка автообнаруженных параметров
if [ -f "${SCRIPT_DIR}/discover.sh" ]; then
	eval "$(${SCRIPT_DIR}/discover.sh)"
else
	echo -e "${RED}Error: discover.sh not found${NC}"
	exit 1
fi

# Пути
export KUBECONFIG="${HOME}/.kube/config"
export GPU_RESTRICT_PROFILE="${REPO_ROOT}/config/gpu/seccomp-profile.json"
export SECURITY_PROFILES_DIR="${REPO_ROOT}/config/security"



# Kubernetes конфигурация
export CLUSTER_NAME="kind-zakenak"

# Автообнаруженные переменные уже загружены из discover.sh
