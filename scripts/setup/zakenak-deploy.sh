#!/bin/bash
#  ______     _                      _    
# |___  /    | |                    | |   
#    / / __ _| |  _ _   ___     ___ | |  _
#   / / / _` | |/ / _`||  _ \ / _` || |/ /
#  / /_| (_| |  < by_Eberil| | (_| ||   < 
# /_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\
#
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# This code is free! Share it, spread peace and technology!

set -e

# Определение путей
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Добавляем новые пути для профилей безопасности
SECURITY_PROFILES_DIR="${REPO_ROOT}/profiles"
GPU_RESTRICT_PROFILE="${SECURITY_PROFILES_DIR}/gpu-restrict.json"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Docker image configuration
ZAKENAK_IMAGE="ghcr.io/i8megabit/zakenak:latest"

# Значения по умолчанию
SKIP_SETUP=false
SKIP_DOCKER=false
SKIP_NVIDIA=false
SKIP_CONVERGE=false
SKIP_SECURITY_CHECK=false
DEBUG=false
NAMESPACE="prod"
ENVIRONMENT="prod"
AUDIT_LEVEL="RequestResponse"
GPU_MEMORY_LIMIT="8Gi"
GPU_USAGE_THRESHOLD=95

# Функция вывода справки
show_help() {
	echo "Использование: $0 [опции]"
	echo ""
	echo "Опции:"
	echo "  --skip-setup         Пропустить настройку кластера"
	echo "  --skip-docker       Пропустить настройку Docker"
	echo "  --skip-nvidia       Пропустить настройку NVIDIA"
	echo "  --skip-converge     Пропустить конвергенцию"
	echo "  --skip-security     Пропустить проверки безопасности"
	echo "  --debug             Включить режим отладки"
	echo "  --namespace         Указать namespace (по умолчанию: prod)"
	echo "  --environment       Указать окружение (по умолчанию: prod)"
	echo "  --audit-level       Уровень аудита (по умолчанию: RequestResponse)"
	echo "  --gpu-memory-limit  Лимит памяти GPU (по умолчанию: 8Gi)"
	echo "  -h, --help          Показать эту справку"
}

# Парсинг аргументов
while [[ $# -gt 0 ]]; do
	case $1 in
		--skip-setup)
			SKIP_SETUP=true
			shift
			;;
		--skip-docker)
			SKIP_DOCKER=true
			shift
			;;
		--skip-nvidia)
			SKIP_NVIDIA=true
			shift
			;;
		--skip-converge)
			SKIP_CONVERGE=true
			shift
			;;
		--skip-security)
			SKIP_SECURITY_CHECK=true
			shift
			;;
		--debug)
			DEBUG=true
			shift
			;;
		--namespace)
			NAMESPACE="$2"
			shift 2
			;;
		--environment)
			ENVIRONMENT="$2"
			shift 2
			;;
		--audit-level)
			AUDIT_LEVEL="$2"
			shift 2
			;;
		--gpu-memory-limit)
			GPU_MEMORY_LIMIT="$2"
			shift 2
			;;
		-h|--help)
			show_help
			exit 0
			;;
		*)
			echo "Неизвестная опция: $1"
			show_help
			exit 1
			;;
	esac
done

# Функция проверки ошибок
check_error() {
	if [ $? -ne 0 ]; then
		echo -e "${RED}Ошибка: $1${NC}"
		exit 1
	fi
}

# Функция проверки безопасности
check_security() {
	if [ "$SKIP_SECURITY_CHECK" = false ]; then
		echo -e "${CYAN}Проверка конфигурации безопасности...${NC}"
		
		# Проверка наличия профиля GPU restrict
		if [ ! -f "$GPU_RESTRICT_PROFILE" ]; then
			echo -e "${RED}Ошибка: Отсутствует профиль ограничений GPU${NC}"
			exit 1
		fi

		# Проверка прав доступа к профилям безопасности
		if [ -d "$SECURITY_PROFILES_DIR" ]; then
			find "$SECURITY_PROFILES_DIR" -type f -exec chmod 644 {} \;
			find "$SECURITY_PROFILES_DIR" -type d -exec chmod 755 {} \;
		fi

		# Проверка настроек Docker
		if ! docker info --format '{{.SecurityOptions}}' | grep -q "name=seccomp,profile=default"; then
			echo -e "${YELLOW}Предупреждение: Seccomp профиль Docker не активирован${NC}"
		fi

		# Проверка NVIDIA Container Toolkit
		if ! command -v nvidia-container-cli &> /dev/null; then
			echo -e "${RED}Ошибка: NVIDIA Container Toolkit не установлен${NC}"
			exit 1
		fi
	fi
}

# Функция настройки Docker и NVIDIA
setup_docker_nvidia() {
	if [ "$SKIP_DOCKER" = false ]; then
		echo -e "${CYAN}Настройка Docker с расширенной безопасностью...${NC}"
		
		# Создаем директорию для профилей безопасности
		mkdir -p "$SECURITY_PROFILES_DIR"
		
		# Проверяем и устанавливаем базовые настройки безопасности Docker
		sudo "${SCRIPT_DIR}/docker-setup.sh"
		check_error "Настройка Docker завершилась с ошибкой"
	fi

	if [ "$SKIP_NVIDIA" = false ]; then
		echo -e "${CYAN}Настройка NVIDIA с расширенной безопасностью...${NC}"
		
		# Проверка драйверов и возможностей
		if ! command -v nvidia-smi &> /dev/null; then
			echo -e "${RED}NVIDIA драйверы не установлены${NC}"
			exit 1
		fi

		# Проверка версии CUDA
		CUDA_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
		if [[ "${CUDA_VERSION%%.*}" -lt 12 ]]; then
			echo -e "${YELLOW}Предупреждение: Рекомендуется CUDA версии 12.8+${NC}"
		fi

		# Проверка Compute Capability
		CC=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader)
		if [[ "${CC%%.*}" -lt 7 ]]; then
			echo -e "${RED}Ошибка: Требуется GPU с Compute Capability 7.0+${NC}"
			exit 1
		fi
	fi
}

# Функция настройки кластера
setup_cluster() {
	if [ "$SKIP_SETUP" = false ]; then
		echo -e "${CYAN}Настройка кластера...${NC}"
		
		# Подготовка переменных окружения
		export ZAKENAK_DEBUG=$DEBUG
		export ZAKENAK_NAMESPACE=$NAMESPACE
		export ZAKENAK_ENV=$ENVIRONMENT

		# Запуск setup через Docker
		docker run --rm --gpus all \
			-v "${REPO_ROOT}:/workspace" \
			-v "${REPO_ROOT}/kubeconfig.yaml:/root/.kube/config" \
			-e ZAKENAK_DEBUG="${DEBUG}" \
			-e ZAKENAK_NAMESPACE="${NAMESPACE}" \
			-e ZAKENAK_ENV="${ENVIRONMENT}" \
			"${ZAKENAK_IMAGE}" setup \
			--workdir /workspace \
			--namespace "${NAMESPACE}"
		
		check_error "Настройка кластера завершилась с ошибкой"
	fi
}

# Функция конвергенции
run_converge() {
	if [ "$SKIP_CONVERGE" = false ]; then
		echo -e "${CYAN}Запуск конвергенции с расширенной безопасностью...${NC}"
		
		# Подготовка переменных окружения
		export ZAKENAK_DEBUG=$DEBUG
		export ZAKENAK_NAMESPACE=$NAMESPACE
		export ZAKENAK_ENV=$ENVIRONMENT
		
		# Запуск конвергенции через Docker с расширенными мерами безопасности
		docker run --rm --gpus all \
			--security-opt=no-new-privileges \
			--security-opt seccomp="$GPU_RESTRICT_PROFILE" \
			--cap-drop ALL \
			--cap-add SYS_ADMIN \
			--pids-limit 100 \
			--cpus 2.0 \
			--memory "$GPU_MEMORY_LIMIT" \
			--device-read-bps /dev/sda:1mb \
			--device-write-bps /dev/sda:1mb \
			-v "${REPO_ROOT}:/workspace:ro" \
			-v "${REPO_ROOT}/kubeconfig.yaml:/root/.kube/config:ro" \
			-e ZAKENAK_DEBUG="${DEBUG}" \
			-e ZAKENAK_NAMESPACE="${NAMESPACE}" \
			-e ZAKENAK_ENV="${ENVIRONMENT}" \
			-e NVIDIA_VISIBLE_DEVICES=all \
			-e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
			-e CUDA_CACHE_DISABLE=1 \
			-e AUDIT_LEVEL="${AUDIT_LEVEL}" \
			-e GPU_USAGE_THRESHOLD="${GPU_USAGE_THRESHOLD}" \
			--network=host \
			"${ZAKENAK_IMAGE}" converge \
			--config /workspace/zakenak.yaml \
			--namespace "${NAMESPACE}"
		
		check_error "Конвергенция завершилась с ошибкой"
	fi
}

# Функция проверки статуса
check_status() {
	echo -e "${CYAN}Проверка статуса компонентов...${NC}"
	
	# Проверка статуса через Docker
	docker run --rm --gpus all \
		-v "${REPO_ROOT}:/workspace" \
		-v "${REPO_ROOT}/kubeconfig.yaml:/root/.kube/config" \
		"${ZAKENAK_IMAGE}" status \
		--namespace "${NAMESPACE}"
	
	check_error "Проверка статуса завершилась с ошибкой"
}

# Основная функция
main() {
	echo -e "${CYAN}Начало развертывания Zakenak с расширенной безопасностью...${NC}"
	
	# Добавляем проверку безопасности в последовательность выполнения
	check_security
	setup_docker_nvidia
	setup_cluster
	run_converge
	check_status
	
	echo -e "${GREEN}Развертывание успешно завершено!${NC}"
}

# Запуск основной функции
main