#!/usr/bin/bash

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Загрузка общих переменных и баннеров
source "${SCRIPT_DIR}/env"
source "${SCRIPT_DIR}/ascii_banners"

# Директории
CHARTS_DIR="${REPO_ROOT}/helm-charts"
MANIFESTS_DIR="${CHARTS_DIR}/manifests"

# Функция отображения меню
show_menu() {
    clear
    charts_banner
    echo -e "\n${CYAN}Менеджер симлинков Helm чартов${NC}"
    echo -e "${YELLOW}================================${NC}\n"
    echo -e "${GREEN}1)${NC} Создать симлинки на манифесты"
    echo -e "${GREEN}2)${NC} Удалить симлинки"
    echo -e "${GREEN}3)${NC} Показать статус симлинков"
    echo -e "${GREEN}4)${NC} Выход\n"
    echo -e "${CYAN}Выберите действие (1-4):${NC} "
}

# Функция проверки наличия чартов
check_charts() {
    if [ ! -d "$CHARTS_DIR" ]; then
        echo -e "${RED}Ошибка: Директория с чартами не найдена: $CHARTS_DIR${NC}"
        exit 1
    fi
}

# Функция получения списка чартов
get_charts() {
    local charts=()
    for chart_dir in "${CHARTS_DIR}"/*; do
        if [ -f "${chart_dir}/Chart.yaml" ]; then
            charts+=("$(basename "${chart_dir}")")
        fi
    done
    echo "${charts[@]}"
}

# Функция создания симлинков
create_symlinks() {
    echo -e "\n${CYAN}Создание симлинков на манифесты...${NC}\n"
    local count=0
    local total=0
    
    local charts=($(get_charts))
    total=${#charts[@]}
    
    echo -e "${YELLOW}Найдено чартов: $total${NC}\n"
    
    for chart in "${charts[@]}"; do
        local target_link="${CHARTS_DIR}/${chart}/manifests"
        
        if [ ! -L "$target_link" ]; then
            ln -s "$MANIFESTS_DIR" "$target_link"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓${NC} Создана ссылка: ${CYAN}${chart}/manifests${NC} → ${YELLOW}${MANIFESTS_DIR}${NC}"
                ((count++))
            else
                echo -e "${RED}✗${NC} Ошибка создания ссылки для ${CYAN}${chart}${NC}"
            fi
        else
            echo -e "${YELLOW}⚠${NC} Ссылка уже существует: ${CYAN}${chart}/manifests${NC}"
        fi
    done
    
    echo -e "\n${GREEN}Создано новых ссылок: $count из $total${NC}"
    echo -e "\n${YELLOW}Нажмите Enter для продолжения...${NC}"
    read
}

# Функция удаления симлинков
remove_symlinks() {
    echo -e "\n${CYAN}Удаление симлинков...${NC}\n"
    local count=0
    local total=0
    
    local charts=($(get_charts))
    total=${#charts[@]}
    
    echo -e "${YELLOW}Найдено чартов: $total${NC}\n"
    
    for chart in "${charts[@]}"; do
        local target_link="${CHARTS_DIR}/${chart}/manifests"
        
        if [ -L "$target_link" ]; then
            rm "$target_link"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓${NC} Удалена ссылка: ${CYAN}${chart}/manifests${NC}"
                ((count++))
            else
                echo -e "${RED}✗${NC} Ошибка удаления ссылки для ${CYAN}${chart}${NC}"
            fi
        else
            echo -e "${YELLOW}⚠${NC} Ссылка не существует: ${CYAN}${chart}/manifests${NC}"
        fi
    done
    
    echo -e "\n${GREEN}Удалено ссылок: $count из $total${NC}"
    echo -e "\n${YELLOW}Нажмите Enter для продолжения...${NC}"
    read
}

# Функция показа статуса симлинков
show_status() {
    echo -e "\n${CYAN}Статус симлинков:${NC}\n"
    local charts=($(get_charts))
    
    printf "${YELLOW}%-20s %-10s %-40s${NC}\n" "ЧАРТ" "СТАТУС" "ПУТЬ"
    echo -e "${YELLOW}$(printf '=%.0s' {1..70})${NC}"
    
    for chart in "${charts[@]}"; do
        local target_link="${CHARTS_DIR}/${chart}/manifests"
        local status_color="${RED}"
        local status_text="отсутствует"
        local link_path="-"
        
        if [ -L "$target_link" ]; then
            status_color="${GREEN}"
            status_text="активен"
            link_path="$(readlink "$target_link")"
        fi
        
        printf "%-20s ${status_color}%-10s${NC} %-40s\n" "$chart" "$status_text" "$link_path"
    done
    
    echo -e "\n${YELLOW}Нажмите Enter для продолжения...${NC}"
    read
}

# Основная логика
check_charts

while true; do
    show_menu
    read -r choice
    
    case $choice in
        1) create_symlinks ;;
        2) remove_symlinks ;;
        3) show_status ;;
        4) 
            echo -e "\n${GREEN}Выход из программы...${NC}"
            success_banner
            exit 0
            ;;
        *)
            echo -e "\n${RED}Неверный выбор. Пожалуйста, выберите 1-4${NC}"
            sleep 2
            ;;
    esac
done