#!/usr/bin/bash
#   ____ _____ ____ _____ 
#  / ___|  ___| __ )_   _|
# | |   | |_  |  _ \ | |  
# | |___|  _| | |_) || |  
#  \____|_|   |____/ |_|  
#                by @eberil
#
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# This code is free! Share it, spread peace and technology!
# "Because certificates should be trusted!"

# Определение пути к директории скрипта и корню репозитория
export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export TOOLS_DIR="${BASE_DIR}/tools/k8s-kind-setup"
export SCRIPTS_ENV_PATH="${TOOLS_DIR}/env/src/env.sh"

# Загрузка общих переменных и баннеров
if [ -f "${SCRIPTS_ENV_PATH}" ]; then
    source "${SCRIPTS_ENV_PATH}"
else
    # Fallback colors if env.sh is not available
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
    
    # Fallback variables
    NAMESPACE_CERT_MANAGER="cert-manager"
    NAMESPACE_PROD="prod"
fi

# Определение констант
CA_SECRET_NAME="root-ca-key-pair"
OUTPUT_DIR="${HOME}/zakenak-certs"
CA_CERT_FILE="${OUTPUT_DIR}/zakenak-root-ca.crt"

# Функция для проверки ошибок
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}$1${NC}"
        exit 1
    fi
}

# Отображение баннера при старте
echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}   Экспорт корневого сертификата CA  ${NC}"
echo -e "${CYAN}=====================================${NC}"
echo ""

# Проверка наличия kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Ошибка: kubectl не установлен${NC}"
    exit 1
fi

# Проверка доступности кластера
echo -e "${CYAN}Проверка доступности кластера...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Ошибка: Нет доступа к кластеру Kubernetes${NC}"
    exit 1
fi

# Создание директории для сертификатов
echo -e "${CYAN}Создание директории для сертификатов...${NC}"
mkdir -p "${OUTPUT_DIR}"
check_error "Не удалось создать директорию ${OUTPUT_DIR}"

# Проверка наличия секрета с корневым CA
echo -e "${CYAN}Проверка наличия секрета с корневым CA...${NC}"
if ! kubectl get secret "${CA_SECRET_NAME}" -n "${NAMESPACE_PROD}" &> /dev/null; then
    echo -e "${RED}Ошибка: Секрет ${CA_SECRET_NAME} не найден в namespace ${NAMESPACE_PROD}${NC}"
    echo -e "${YELLOW}Возможно, вам нужно установить local-ca чарт${NC}"
    exit 1
fi

# Экспорт корневого CA сертификата
echo -e "${CYAN}Экспорт корневого CA сертификата...${NC}"
kubectl get secret "${CA_SECRET_NAME}" -n "${NAMESPACE_PROD}" -o jsonpath='{.data.tls\.crt}' | base64 --decode > "${CA_CERT_FILE}"
check_error "Не удалось экспортировать корневой CA сертификат"

echo -e "${GREEN}Корневой CA сертификат успешно экспортирован в ${CA_CERT_FILE}${NC}"

# Вывод инструкций по импорту сертификата
echo -e "\n${YELLOW}Инструкции по импорту сертификата в браузер:${NC}"

# Chrome/Edge (Windows)
echo -e "\n${CYAN}Chrome/Edge (Windows):${NC}"
echo -e "1. Откройте настройки браузера"
echo -e "2. Перейдите в 'Конфиденциальность и безопасность' -> 'Безопасность' -> 'Управление сертификатами'"
echo -e "3. Перейдите на вкладку 'Доверенные корневые центры сертификации'"
echo -e "4. Нажмите 'Импорт' и следуйте инструкциям мастера импорта сертификатов"
echo -e "5. Выберите файл ${CA_CERT_FILE}"
echo -e "6. Перезапустите браузер"

# Chrome/Edge (macOS)
echo -e "\n${CYAN}Chrome/Edge (macOS):${NC}"
echo -e "1. Откройте 'Связка ключей'"
echo -e "2. Перетащите файл ${CA_CERT_FILE} в список сертификатов"
echo -e "3. Дважды щелкните на импортированном сертификате"
echo -e "4. Разверните секцию 'Доверие' и выберите 'Всегда доверять'"
echo -e "5. Закройте окно и введите пароль администратора"
echo -e "6. Перезапустите браузер"

# Firefox
echo -e "\n${CYAN}Firefox:${NC}"
echo -e "1. Откройте настройки Firefox"
echo -e "2. Перейдите в 'Конфиденциальность и защита' -> 'Сертификаты' -> 'Просмотр сертификатов'"
echo -e "3. Перейдите на вкладку 'Центры сертификации'"
echo -e "4. Нажмите 'Импортировать' и выберите файл ${CA_CERT_FILE}"
echo -e "5. Отметьте 'Доверять этому CA при идентификации веб-сайтов'"
echo -e "6. Нажмите 'OK' и перезапустите браузер"

# Linux
echo -e "\n${CYAN}Linux (Ubuntu/Debian):${NC}"
echo -e "1. Скопируйте сертификат в директорию доверенных CA:"
echo -e "   sudo cp ${CA_CERT_FILE} /usr/local/share/ca-certificates/zakenak-root-ca.crt"
echo -e "2. Обновите хранилище сертификатов:"
echo -e "   sudo update-ca-certificates"
echo -e "3. Перезапустите браузер"

echo -e "\n${GREEN}После импорта сертификата вы сможете безопасно открывать:${NC}"
echo -e "${CYAN}https://dashboard.prod.local${NC}"
echo -e "${CYAN}https://ollama.prod.local${NC}"
echo -e "${CYAN}https://webui.prod.local${NC}"

echo -e "\n${YELLOW}Примечание: Этот сертификат действителен только для локальной разработки.${NC}"
echo -e "${YELLOW}Не импортируйте его в браузеры, используемые для доступа к важным сайтам.${NC}"