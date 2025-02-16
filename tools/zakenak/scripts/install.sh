#!/usr/bin/env bash

# Copyright (c) 2024 Mikhail Eberil
# Installation script for Ƶakenak™®

set -e

# Цвета для вывода
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}Установка Ƶakenak™®...${NC}"

# Проверка наличия CUDA
check_cuda() {
    if ! command -v nvidia-smi &> /dev/null; then
        echo -e "${RED}CUDA не установлена. Установите CUDA 12.8 или выше.${NC}"
        exit 1
    fi
}

# Установка зависимостей
install_dependencies() {
    echo -e "${CYAN}Установка зависимостей...${NC}"
    sudo apt-get update
    sudo apt-get install -y \
        make \
        golang \
        docker.io
}

# Сборка и установка
build_and_install() {
    echo -e "${CYAN}Сборка Ƶakenak™®...${NC}"
    make build
    
    echo -e "${CYAN}Установка Ƶakenak™®...${NC}"
    sudo make install
}

# Проверка установки
verify_installation() {
    if command -v zakenak &> /dev/null; then
        echo -e "${GREEN}Ƶakenak™® успешно установлен!${NC}"
        zakenak version
    else
        echo -e "${RED}Ошибка установки Ƶakenak™®${NC}"
        exit 1
    fi
}

main() {
    check_cuda
    install_dependencies
    build_and_install
    verify_installation
}

main