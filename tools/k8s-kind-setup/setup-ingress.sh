#!/usr/bin/bash
#  ___                              
# |_ _|_ __   __ _ _ __ ___  ___ ___
#  | || '_ \ / _` | '__/ _ \/ __/ __|
#  | || | | | (_| | | |  __/\__ \__ \
# |___|_| |_|\__, |_|  \___||___/___/
#            |___/         by @eberil
#
# Copyright (c) 2024 Mikhail Eberil
# This code is free! Share it, spread peace and technology!
# "Because Ingress should just work!"

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Загрузка общих переменных и баннеров
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/ascii_banners.sh"

# Отображение баннера при старте
ingress_banner
echo ""

# ... rest of the code