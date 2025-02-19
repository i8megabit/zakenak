#!/usr/bin/bash
#   _____ _                _       
#  / ____| |              | |      
# | |    | |__   __ _ _ __| |_ ___ 
# | |    | '_ \ / _` | '__| __/ __|
# | |____| | | | (_| | |  | |_\__ \
#  \_____|_| |_|\__,_|_|   \__|___/
#                         by @eberil
#
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# Helm Charts Management Tool
# Version: 1.2.0
#
# HUJAK-HUJAK PRODUCTION PRESENTS...
# "Because managing charts shouldn't be a pain"

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
K8S_KIND_SETUP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CHARTS_DIR="${TOOLS_DIR}/../helm-charts"

# Загрузка общих переменных и баннеров
source "${K8S_KIND_SETUP_DIR}/env.sh"
source "${K8S_KIND_SETUP_DIR}/ascii-banners/src/ascii_banners.sh"

# Отображение баннера при старте
charts_banner
echo ""

# Функция для проверки ошибок
check_error() {
	if [ $? -ne 0 ]; then
		echo -e "${RED}$1${NC}"
		exit 1
	fi
}

# Функция для вывода справки
show_help() {
	echo "Использование: $0 <команда> <имя_чарта>"
	echo ""
	echo "Команды:"
	echo "  install   - Установить чарт"
	echo "  uninstall - Удалить чарт"
	echo "  upgrade   - Обновить чарт"
	echo "  list      - Показать список установленных чартов"
	echo ""
	echo "Пример:"
	echo "  $0 install ollama"
	exit 0
}

# Проверка наличия аргументов
if [ $# -lt 1 ]; then
	show_help
fi

# Обработка команд
command=$1
chart_name=$2

case $command in
	"install")
		if [ -z "$chart_name" ]; then
			echo -e "${RED}Ошибка: Не указано имя чарта${NC}"
			show_help
		fi
		echo -e "${CYAN}Установка чарта $chart_name...${NC}"
		helm upgrade --install $chart_name "${CHARTS_DIR}/$chart_name" \
			--namespace default --create-namespace
		check_error "Ошибка при установке чарта $chart_name"
		;;
	"uninstall")
		if [ -z "$chart_name" ]; then
			echo -e "${RED}Ошибка: Не указано имя чарта${NC}"
			show_help
		fi
		echo -e "${CYAN}Удаление чарта $chart_name...${NC}"
		helm uninstall $chart_name --namespace default
		check_error "Ошибка при удалении чарта $chart_name"
		;;
	"upgrade")
		if [ -z "$chart_name" ]; then
			echo -e "${RED}Ошибка: Не указано имя чарта${NC}"
			show_help
		fi
		echo -e "${CYAN}Обновление чарта $chart_name...${NC}"
		helm upgrade $chart_name "${CHARTS_DIR}/$chart_name" \
			--namespace default
		check_error "Ошибка при обновлении чарта $chart_name"
		;;
	"list")
		echo -e "${CYAN}Список установленных чартов:${NC}"
		helm list --all-namespaces
		check_error "Ошибка при получении списка чартов"
		;;
	*)
		echo -e "${RED}Неизвестная команда: $command${NC}"
		show_help
		;;
esac

echo -e "${GREEN}Операция успешно завершена!${NC}"