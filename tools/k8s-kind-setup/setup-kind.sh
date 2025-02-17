#!/bin/bash
#
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# 
# This file is part of Ƶakenak™® project.
# https://github.com/i8megabit/zakenak
#
# This program is free software and is released under the terms of the MIT License.
# See LICENSE.md file in the project root for full license information.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#
# TRADEMARK NOTICE:
# Ƶakenak™® and the Ƶakenak logo are registered trademarks of Mikhail Eberil.
# All rights reserved. The Ƶakenak trademark and brand may not be used in any way 
# without express written permission from the trademark owner.
#  _  _____ ____  
# | |/ / _ \___ \ 
# | ' / (_) |__) |
# | . \> _ </ __/ 
# |_|\_\___/_____|
#            by @eberil

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Загрузка общих переменных и баннеров
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/ascii_banners.sh"

# Отображение баннера при старте
k8s_banner
echo ""

echo -e "${YELLOW}Начинаем установку кластера Kind...${NC}"

# Предварительная загрузка необходимых образов
echo -e "${CYAN}Предварительная загрузка образов...${NC}"
docker pull kindest/node:v1.27.3
docker pull nginx:1.25.3
docker pull quay.io/jetstack/cert-manager-controller:v1.12.0

# Функция создания кластера
setup_kind_cluster() {
    echo -e "${CYAN}Проверка существующего кластера...${NC}"
    if kind get clusters 2>/dev/null | grep -q "^kind$"; then
        echo -e "${YELLOW}Обнаружен существующий кластер 'kind'. Удаляем...${NC}"
        kind delete cluster
        check_error "Не удалось удалить существующий кластер"
        sleep 5
    fi
    
    echo -e "${CYAN}Создание нового кластера Kind...${NC}"
    kind create cluster --config "${SCRIPT_DIR}/kubeconfig.yaml" --image kindest/node:v1.27.3
    check_error "Не удалось создать кластер Kind"
    
    # Ожидание готовности узлов
    echo -e "${CYAN}Ожидание готовности узлов кластера...${NC}"
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    check_error "Узлы кластера не готовы"
}

# Запуск установки
setup_kind_cluster

echo -e "\n"
success_banner
echo -e "\n${GREEN}Установка кластера Kind успешно завершена!${NC}"