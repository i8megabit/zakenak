#!/usr/bin/bash

# Скрипт помогает обновить hosts-файл Windows из WSL

# Цветовые коды
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Проверяем, запущено ли окружение в WSL
if ! grep -q "microsoft" /proc/version && ! grep -q "WSL" /proc/version; then
    echo -e "${RED}Скрипт нужно запускать в WSL. Он помогает обновить hosts-файл Windows.${NC}"
    exit 1
fi

# Путь к директории скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS_SCRIPT="${SCRIPT_DIR}/update-windows-hosts.ps1"

# Проверяем, существует ли PowerShell-скрипт
if [ ! -f "$PS_SCRIPT" ]; then
    echo -e "${RED}PowerShell-скрипт не найден по пути: ${PS_SCRIPT}${NC}"
    exit 1
fi

# Имя пользователя Windows
WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
if [ -z "$WIN_USER" ]; then
    echo -e "${YELLOW}Не удалось определить имя пользователя Windows. Использую 'User'.${NC}"
    WIN_USER="User"
fi

# Копируем PowerShell-скрипт во временную папку Windows
WIN_TEMP="/mnt/c/Users/${WIN_USER}/AppData/Local/Temp"
if [ ! -d "$WIN_TEMP" ]; then
    echo -e "${YELLOW}Папка Temp в Windows не найдена по пути: ${WIN_TEMP}${NC}"
    echo -e "${YELLOW}Пробую альтернативный путь...${NC}"
    WIN_TEMP="/mnt/c/Windows/Temp"
    if [ ! -d "$WIN_TEMP" ]; then
        echo -e "${RED}Не удалось найти папку Temp в Windows. Запустите PowerShell-скрипт вручную.${NC}"
        echo -e "${CYAN}Файл скрипта: ${PS_SCRIPT}${NC}"
        exit 1
    fi
fi

# Копируем скрипт
WIN_PS_SCRIPT="${WIN_TEMP}/update-windows-hosts.ps1"
cp "$PS_SCRIPT" "$WIN_PS_SCRIPT" 2>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}Не удалось скопировать PowerShell-скрипт во временную папку Windows.${NC}"
    echo -e "${CYAN}Запустите PowerShell-скрипт вручную: ${PS_SCRIPT}${NC}"
    exit 1
fi

# Конвертируем путь в формат Windows
WIN_PS_SCRIPT_PATH=$(wslpath -w "$WIN_PS_SCRIPT" 2>/dev/null)
if [ -z "$WIN_PS_SCRIPT_PATH" ]; then
    WIN_PS_SCRIPT_PATH="C:\\Users\\${WIN_USER}\\AppData\\Local\\Temp\\update-windows-hosts.ps1"
fi

echo -e "${GREEN}PowerShell-скрипт скопирован в: ${WIN_PS_SCRIPT_PATH}${NC}"
echo -e "\n${CYAN}Чтобы обновить hosts-файл Windows:${NC}"
echo -e "${YELLOW}1. Откройте PowerShell от имени администратора${NC}"
echo -e "${YELLOW}2. Выполните команду:${NC}"
echo -e "${CYAN}   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process; ${WIN_PS_SCRIPT_PATH}${NC}"

# Пытаемся запустить скрипт автоматически
echo -e "\n${CYAN}Пробую запустить скрипт напрямую (может потребоваться подтверждение администратора):${NC}"
powershell.exe -Command "Start-Process PowerShell -ArgumentList '-ExecutionPolicy Bypass -File \"${WIN_PS_SCRIPT_PATH}\"' -Verb RunAs" 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}PowerShell-скрипт запущен. Подтвердите запрос администратора в Windows.${NC}"
else
    echo -e "${YELLOW}Не удалось автоматически запустить PowerShell с правами администратора.${NC}"
    echo -e "${YELLOW}Выполните шаги вручную, указанные выше.${NC}"
fi

echo -e "\n${CYAN}После выполнения скрипта будут доступны:${NC}"
echo -e "${GREEN}- https://dashboard.prod.local${NC}"
echo -e "${GREEN}- https://ollama.prod.local${NC}"
echo -e "${GREEN}- https://webui.prod.local${NC}"