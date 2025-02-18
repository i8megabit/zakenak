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

# Парсинг аргументов
NO_REMOVE=false
for arg in "$@"; do
    case $arg in
        --no-remove)
            NO_REMOVE=true
            shift
            ;;
    esac
done

# Функция очистки при ошибках
cleanup() {
    if [ "$NO_REMOVE" = true ]; then
        echo -e "${YELLOW}Пропуск очистки (--no-remove)...${NC}"
        error_banner
        echo -e "${RED}Установка прервана. Проверьте логи для деталей.${NC}"
        exit 1
    fi

    echo -e "${RED}Произошла ошибка, выполняем очистку...${NC}"
    
    # Удаление манифестов
    rm -f "${REPO_ROOT}/helm-charts/manifests/etcd.yaml" \
          "${REPO_ROOT}/helm-charts/manifests/kube-apiserver.yaml" \
          "${REPO_ROOT}/helm-charts/manifests/kube-controller-manager.yaml" \
          "${REPO_ROOT}/helm-charts/manifests/kube-scheduler.yaml"
    
    # Удаление конфигурационных файлов
    rm -f "${REPO_ROOT}/kind-config.yaml" \
          "${REPO_ROOT}/kubeconfig.yaml"
    
    # Удаление кластера если он был создан
    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        echo -e "${YELLOW}Удаляем кластер ${CLUSTER_NAME}...${NC}"
        kind delete cluster --name "${CLUSTER_NAME}"
    fi
    
    # Очистка Docker
    echo -e "${YELLOW}Очистка Docker ресурсов...${NC}"
    docker system prune -f
    
    error_banner
    echo -e "${RED}Установка прервана. Проверьте логи для деталей.${NC}"
    exit 1
}

# Установка trap для перехвата ошибок
trap cleanup ERR

# Функция проверки ошибок
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка: $1${NC}"
        cleanup
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
    fi

    # Проверка kind
    if ! command -v kind &> /dev/null; then
        echo -e "${YELLOW}Kind не установлен, устанавливаем...${NC}"
        go install sigs.k8s.io/kind@latest
    fi
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
}

# Функция создания кластера
setup_cluster() {
    echo -e "${CYAN}Создание кластера...${NC}"
    
    # Генерация конфигурации кластера
    "${SCRIPT_DIR}/generate-kubeconfig.sh"
    check_error "Ошибка генерации конфигурации кластера"
    
    # Проверка существующего кластера
    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        echo -e "${YELLOW}Обнаружен существующий кластер '${CLUSTER_NAME}'. Удаляем...${NC}"
        kind delete cluster --name "${CLUSTER_NAME}"
        check_error "Не удалось удалить существующий кластер"
        sleep 5
    fi
    
    # Создание нового кластера
    kind create cluster --name "${CLUSTER_NAME}" --config "${REPO_ROOT}/kind-config.yaml"
    check_error "Ошибка создания кластера"
    
    # Ожидание готовности узлов
    echo -e "${CYAN}Ожидание готовности узлов кластера...${NC}"
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    check_error "Узлы кластера не готовы"

    # Обновление kubeconfig правильными данными
    kind get kubeconfig --name "${CLUSTER_NAME}" > "${REPO_ROOT}/kubeconfig.yaml"
    check_error "Ошибка обновления kubeconfig"
}

# Функция генерации конфигурации zakenak
generate_zakenak_config() {
    echo -e "${CYAN}Генерация конфигурации zakenak...${NC}"
    
    # Проверка наличия директории helm-charts
    if [ ! -d "${REPO_ROOT}/helm-charts" ]; then
        echo -e "${RED}Ошибка: директория helm-charts не найдена${NC}"
        exit 1
    }

    # Создание временного массива для хранения конфигурации чартов
    declare -a chart_configs

    # Обход всех директорий в helm-charts
    for chart_dir in "${REPO_ROOT}"/helm-charts/*/; do
        if [ -d "$chart_dir" ]; then
            # Получение имени чарта из пути
            chart_name=$(basename "$chart_dir")
            
            # Формирование конфигурации для чарта
            chart_config="    - name: $chart_name\n      path: ./helm-charts/$chart_name"
            
            # Проверка наличия values файлов
            if [ -f "${chart_dir}/values.yaml" ]; then
                chart_config+="\n      values:\n        - values.yaml"
                
                # Проверка дополнительных values файлов
                if [ -f "${chart_dir}/values-prod.yaml" ]; then
                    chart_config+="\n        - values-prod.yaml"
                fi
                if [ -f "${chart_dir}/values-gpu.yaml" ]; then
                    chart_config+="\n        - values-gpu.yaml"
                fi
            fi
            
            chart_configs+=("$chart_config")
        fi
    done

    # Генерация файла конфигурации
    cat > "${REPO_ROOT}/zakenak.yaml" << EOF
version: "1.0"
project: zakenak
environment: prod

# Настройки развертывания
deploy:
  namespace: prod
  charts:
$(printf '%s\n' "${chart_configs[@]}")

# Настройки GPU
build:
  gpu:
    enabled: true
    runtime: nvidia
    memory: "8Gi"
    devices: "all"
    capabilities:
      - compute
      - utility
    options:
      - "device=all"
      - "require=cuda>=12.0"

# Настройки безопасности
security:
  rbac:
    enabled: true
    serviceAccount: zakenak
  networkPolicies:
    enabled: true
  podSecurityContext:
    runAsNonRoot: true
    runAsUser: 1000
EOF

    check_error "Ошибка генерации конфигурации zakenak"
    echo -e "${GREEN}Конфигурация zakenak.yaml успешно создана${NC}"
    
    # Вывод сгенерированной конфигурации для отладки
    echo -e "${CYAN}Сгенерированная конфигурация:${NC}"
    cat "${REPO_ROOT}/zakenak.yaml"
}

# Функция установки компонентов
install_components() {
    echo -e "${CYAN}Установка компонентов...${NC}"
    
    # Создание namespace
    echo -e "${CYAN}Создание namespace prod...${NC}"
    kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -
    
    # Ensure KUBECONFIG is set to the correct path
    export KUBECONFIG="${REPO_ROOT}/kubeconfig.yaml"
    
    # Подготовка монтирования для Docker
    echo -e "${CYAN}Подготовка монтирования для Docker...${NC}"
    MOUNT_FLAGS=(
        -v "${REPO_ROOT}:/workspace"
        -v "${REPO_ROOT}/kubeconfig.yaml:/root/.kube/config:ro"
        -v "${HOME}/.cache/zakenak:/root/.cache/zakenak"
        --network host
    )

    # Проверка конфигурационного файла
    echo -e "${CYAN}Проверка конфигурационного файла zakenak.yaml...${NC}"
    if [ ! -f "${REPO_ROOT}/zakenak.yaml" ]; then
        echo -e "${RED}Ошибка: файл ${REPO_ROOT}/zakenak.yaml не найден${NC}"
        exit 1
    fi

    # Вывод содержимого конфига для отладки
    echo -e "${CYAN}Содержимое конфигурационного файла:${NC}"
    cat "${REPO_ROOT}/zakenak.yaml"
    
    # Проверка синтаксиса YAML
    echo -e "${CYAN}Проверка синтаксиса YAML...${NC}"
    if ! python3 -c "import yaml; yaml.safe_load(open('${REPO_ROOT}/zakenak.yaml'))"; then
        echo -e "${RED}Ошибка: некорректный синтаксис YAML в файле конфигурации${NC}"
        exit 1
    fi

    # Установка компонентов через zakenak в Docker
    echo -e "${CYAN}Запуск конвергентного развертывания через zakenak...${NC}"
    docker run --gpus all \
        "${MOUNT_FLAGS[@]}" \
        -e NVIDIA_VISIBLE_DEVICES=all \
        -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
        -e KUBECONFIG=/root/.kube/config \
        -e ZAKENAK_DEBUG=true \
        ghcr.io/i8megabit/zakenak:latest \
        converge \
        --config /workspace/zakenak.yaml \
        --kubeconfig /root/.kube/config
    
    DEPLOY_STATUS=$?
    if [ $DEPLOY_STATUS -ne 0 ]; then
        echo -e "${RED}Ошибка при развертывании компонентов (код: $DEPLOY_STATUS)${NC}"
        echo -e "${YELLOW}Проверьте следующие моменты:${NC}"
        echo "1. Правильность синтаксиса YAML в zakenak.yaml"
        echo "2. Доступность кластера Kubernetes"
        echo "3. Наличие необходимых прав доступа"
        check_error "Ошибка развертывания компонентов"
    fi

    # Проверка статуса развертывания
    echo -e "${CYAN}Проверка статуса компонентов...${NC}"
    docker run --gpus all \
        "${MOUNT_FLAGS[@]}" \
        -e KUBECONFIG=/root/.kube/config \
        ghcr.io/i8megabit/zakenak:latest \
        status \
        --kubeconfig /root/.kube/config
    check_error "Ошибка проверки статуса компонентов"

    # Ожидание готовности всех компонентов
    echo -e "${CYAN}Ожидание готовности всех компонентов...${NC}"
    kubectl wait --for=condition=Ready pods --all -n prod --timeout=300s
    check_error "Компоненты не готовы"
}


# Функция проверки установки
verify_installation() {
    echo -e "${CYAN}Проверка установки...${NC}"
    
    # Проверка узлов
    kubectl get nodes
    check_error "Ошибка получения списка узлов"
    
    # Проверка подов
    kubectl get pods -n prod
    check_error "Ошибка получения списка подов"
    
    # Проверка GPU
    kubectl exec -it -n prod deployment/ollama -- nvidia-smi
    check_error "Ошибка проверки GPU"
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
    generate_zakenak_config
    install_components
    verify_installation
    
    echo -e "\n"
    success_banner
    echo -e "\n${GREEN}Установка кластера успешно завершена!${NC}"
}

# Запуск установки
main "$@"
