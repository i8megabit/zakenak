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
DEBUG=false
NAMESPACE="prod"
ENVIRONMENT="prod"

# Функция вывода справки
show_help() {
	echo "Использование: $0 [опции]"
	echo ""
	echo "Опции:"
	echo "  --skip-setup     Пропустить настройку кластера"
	echo "  --skip-docker    Пропустить настройку Docker"
	echo "  --skip-nvidia    Пропустить настройку NVIDIA"
	echo "  --skip-converge  Пропустить конвергенцию"
	echo "  --debug          Включить режим отладки"
	echo "  --namespace      Указать namespace (по умолчанию: prod)"
	echo "  --environment    Указать окружение (по умолчанию: prod)"
	echo "  -h, --help       Показать эту справку"
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

# Функция настройки Docker и NVIDIA
setup_docker_nvidia() {
	if [ "$SKIP_DOCKER" = false ]; then
		echo -e "${CYAN}Настройка Docker...${NC}"
		sudo "${SCRIPT_DIR}/docker-setup.sh"
		check_error "Настройка Docker завершилась с ошибкой"
	fi

	if [ "$SKIP_NVIDIA" = false ]; then
		echo -e "${CYAN}Настройка NVIDIA...${NC}"
		if ! command -v nvidia-smi &> /dev/null; then
			echo -e "${RED}NVIDIA драйверы не установлены${NC}"
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
		echo -e "${CYAN}Запуск конвергенции...${NC}"
		
		# Подготовка переменных окружения
		export ZAKENAK_DEBUG=$DEBUG
		export ZAKENAK_NAMESPACE=$NAMESPACE
		export ZAKENAK_ENV=$ENVIRONMENT

		# Запуск конвергенции через Docker
		docker run --rm --gpus all \
			-v "${REPO_ROOT}:/workspace" \
			-v "${REPO_ROOT}/kubeconfig.yaml:/root/.kube/config" \
			-e ZAKENAK_DEBUG="${DEBUG}" \
			-e ZAKENAK_NAMESPACE="${NAMESPACE}" \
			-e ZAKENAK_ENV="${ENVIRONMENT}" \
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
	echo -e "${CYAN}Начало развертывания Zakenak...${NC}"
	
	# Последовательное выполнение этапов
	setup_docker_nvidia
	setup_cluster
	run_converge
	check_status
	
	echo -e "${GREEN}Развертывание успешно завершено!${NC}"
}

# Запуск основной функции
main