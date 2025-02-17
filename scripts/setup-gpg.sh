#!/bin/bash

# Copyright (c) 2025 Mikhail Eberil
# This file is part of Zakenak project.

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Настройка GPG ключа для Git${NC}"

# Проверка установки GPG
if ! command -v gpg &> /dev/null; then
	echo -e "${RED}GPG не установлен. Установка...${NC}"
	sudo apt-get update
	sudo apt-get install -y gnupg2
fi

# Генерация GPG ключа
echo -e "${GREEN}Генерация нового GPG ключа...${NC}"
gpg --full-generate-key

# Получение ID ключа
KEY_ID=$(gpg --list-secret-keys --keyid-format=long | grep sec | awk '{print $2}' | cut -d'/' -f2)

# Экспорт публичного ключа
echo -e "${GREEN}Экспорт публичного ключа...${NC}"
gpg --armor --export $KEY_ID

# Настройка Git для использования GPG
git config --global user.signingkey $KEY_ID
git config --global commit.gpgsign true

echo -e "${GREEN}GPG ключ успешно создан и настроен!${NC}"
echo -e "ID вашего ключа: ${GREEN}$KEY_ID${NC}"
echo -e "\nДобавьте публичный ключ в ваш GitHub аккаунт:"
echo -e "1. Скопируйте весь блок выше (от BEGIN до END)"
echo -e "2. Перейдите на https://github.com/settings/keys"
echo -e "3. Нажмите 'New GPG key'"
echo -e "4. Вставьте скопированный ключ"

# Проверка настройки
echo -e "\n${GREEN}Проверка настройки Git:${NC}"
echo "user.signingkey: $(git config --global user.signingkey)"
echo "commit.gpgsign: $(git config --global commit.gpgsign)"