#!/bin/bash
#
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# This code is free! Share it, spread peace and technology!
# "Because permissions should just work!"

# Определение цветов для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Путь к директории tools
TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}Исправление прав доступа для директорий...${NC}"

# Установка базовых прав для директории tools
chmod 755 "$TOOLS_DIR"

# Список директорий для исправления
directories=(
    "connectivity-check"
    "helm-deployer"
    "helm-setup"
    "k8s-kind-setup"
    "open-webui-tools"
    "reset-wsl"
    "setup-ingress"
    "setup-wsl"
)

# Исправление прав для каждой директории
for dir in "${directories[@]}"; do
    dir_path="${TOOLS_DIR}/${dir}"
    if [ -d "$dir_path" ]; then
        echo -e "${GREEN}Исправление прав для ${dir}...${NC}"
        chmod -R 755 "$dir_path"
    else
        echo -e "${RED}Директория ${dir} не найдена${NC}"
    fi
done

echo -e "${GREEN}Права доступа успешно исправлены!${NC}"
