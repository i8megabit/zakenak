#!/bin/bash
#  _  _____ ____  
# | |/ / _ \___ \ 
# | ' / (_) |__) |
# | . \> _ </ __/ 
# |_|\_\___/_____|
#            by @eberil
#
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# This code is free! Share it, spread peace and technology!

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Загрузка общих переменных и баннеров
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/ascii_banners.sh"

# Функция проверки ошибок
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка: $1${NC}"
        exit 1
    fi
}

# Функция проверки зависимостей
check_dependencies() {
    echo -e "${CYAN}Проверка зависимостей...${NC}"
    
    # Проверка Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker не установлен${NC}"
        exit 1
    fi
    
    # Проверка nvidia-smi
    if ! command -v nvidia-smi &> /dev/null; then
        echo -e "${RED}NVIDIA драйверы не установлены${NC}"
        exit 1
    }
}

# Функция настройки Docker и NVIDIA
setup_docker_nvidia() {
    echo -e "${CYAN}Настройка Docker и NVIDIA...${NC}"
    
    # Запуск скрипта настройки Docker
    sudo "${SCRIPT_DIR}/docker-setup.sh"
    check_error "Ошибка настройки Docker"
}

# Функция загрузки zakenak
setup_zakenak() {
    echo -e "${CYAN}Загрузка Zakenak...${NC}"
    
    # Загрузка последней версии образа
    docker pull ghcr.io/i8megabit/zakenak:latest
    check_error "Ошибка загрузки образа Zakenak"
    
    # Создание алиаса для удобства использования
    echo 'alias zakenak="docker run --rm --gpus all -v $(pwd):/workspace -v ~/.kube:/root/.kube -v ~/.cache/zakenak:/root/.cache/zakenak --network host ghcr.io/i8megabit/zakenak:latest"' >> ~/.bashrc
    source ~/.bashrc
}

# Функция создания кластера
setup_cluster() {
    echo -e "${CYAN}Создание кластера...${NC}"
    
    # Создание конфигурации
    docker run --rm --gpus all \
        -v "${REPO_ROOT}":/workspace \
        -v ~/.kube:/root/.kube \
        -v ~/.cache/zakenak:/root/.cache/zakenak \
        --network host \
        ghcr.io/i8megabit/zakenak:latest \
        cluster create --gpu --config /workspace/helm-charts/kind-config.yaml
    
    check_error "Ошибка создания кластера"
    
    # Ожидание готовности узлов
    echo -e "${CYAN}Ожидание готовности узлов кластера...${NC}"
    sleep 30

    # Генерация конфигурации кластера
    echo -e "${CYAN}Генерация конфигурации кластера...${NC}"
    "${SCRIPT_DIR}/generate-cluster-config.sh"
    check_error "Ошибка генерации конфигурации кластера"
}

# Функция установки компонентов
install_components() {
    echo -e "${CYAN}Установка компонентов...${NC}"
    
    # Установка компонентов через zakenak
    docker run --rm --gpus all \
        -v "${REPO_ROOT}":/workspace \
        -v ~/.kube:/root/.kube \
        -v ~/.cache/zakenak:/root/.cache/zakenak \
        --network host \
        ghcr.io/i8megabit/zakenak:latest \
        deploy --config /workspace/zakenak.yaml
    
    check_error "Ошибка установки компонентов"
}

# Функция проверки установки
verify_installation() {
    echo -e "${CYAN}Проверка установки...${NC}"
    
    # Проверка через zakenak
    docker run --rm --gpus all \
        -v "${REPO_ROOT}":/workspace \
        -v ~/.kube:/root/.kube \
        -v ~/.cache/zakenak:/root/.cache/zakenak \
        --network host \
        ghcr.io/i8megabit/zakenak:latest \
        status
    
    check_error "Ошибка проверки установки"
}

# Основная функция
main() {
    # Отображение баннера
    k8s_banner
    echo ""
    
    echo -e "${YELLOW}Начинаем установку кластера...${NC}"
    
    # Выполнение шагов установки
    check_dependencies
    setup_docker_nvidia
    setup_zakenak
    setup_cluster
    install_components
    verify_installation
    
    echo -e "\n"
    success_banner
    echo -e "\n${GREEN}Установка кластера успешно завершена!${NC}"
}

# Запуск установки
main