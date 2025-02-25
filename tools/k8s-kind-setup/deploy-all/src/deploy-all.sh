#!/usr/bin/bash
# Загрузка переменных окружения и баннеров
export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export TOOLS_DIR="${BASE_DIR}/tools/k8s-kind-setup"
export SCRIPTS_ENV_PATH="${TOOLS_DIR}/env/src/env.sh"

# Функция вывода справки
show_help() {
    echo "Использование: $0 [--no-wsl] [--help]"
    echo ""
    echo "Опции:"
    echo "  --no-wsl        Пропустить настройку WSL"
    echo "  --help          Показать эту справку"
    echo ""
    exit 0
}


# Парсинг аргументов командной строки
SKIP_WSL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-wsl)
            SKIP_WSL=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Неизвестный параметр: $1"
            show_help
            exit 1
            ;;
    esac
done



source "${SCRIPTS_ENV_PATH}"
source "${SCRIPTS_ASCII_BANNERS_PATH}"

show_deploy_banner

# Функция для логирования
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Проверка конфигурации Kubernetes и доступа charts.sh
check_kubernetes_access() {
    log "Проверка доступа к Kubernetes API..."
    
    # Проверка конфигурации kubectl
    if ! kubectl cluster-info &>/dev/null; then
        log "Ошибка: Нет доступа к кластеру Kubernetes"
        return 1
    fi
    
    # Проверка прав доступа для charts.sh
    if ! kubectl auth can-i create deployments &>/dev/null; then
        log "Ошибка: Недостаточно прав для управления кластером"
        return 1
    fi
    
    # Проверка доступа к Helm
    if ! helm list &>/dev/null; then
        log "Ошибка: Нет доступа к Helm"
        return 1
    fi
    
    log "Проверка доступа к Kubernetes API успешно пройдена"
    return 0
}

# Проверка GPU ресурсов в кластере
check_cluster_gpu() {
    log "Проверка GPU ресурсов в кластере..."
    
    # Проверка наличия GPU узлов
    local gpu_nodes
    gpu_nodes=$(kubectl get nodes -l nvidia.com/gpu=true -o name)
    if [[ -z "$gpu_nodes" ]]; then
        log "Ошибка: GPU узлы не найдены в кластере"
        return 1
    fi
    log "Найдены GPU узлы: $gpu_nodes"
    
    # Проверка статуса NVIDIA device plugin
    local plugin_pods
    plugin_pods=$(kubectl get pods -n kube-system -l k8s-app=nvidia-device-plugin-daemonset -o name)
    if [[ -z "$plugin_pods" ]]; then
        log "Ошибка: NVIDIA device plugin не запущен"
        return 1
    fi
    
    # Проверка статуса подов device plugin
    if ! kubectl wait --for=condition=ready pods -n kube-system -l k8s-app=nvidia-device-plugin-daemonset --timeout=60s &>/dev/null; then
        log "Ошибка: NVIDIA device plugin поды не готовы"
        return 1
    fi
    
    # Проверка доступности GPU ресурсов
    for node in $gpu_nodes; do
        local gpu_count
        gpu_count=$(kubectl get $node -o jsonpath='{.status.allocatable.nvidia\.com/gpu}')
        if [[ -z "$gpu_count" || "$gpu_count" -eq "0" ]]; then
            log "Ошибка: GPU ресурсы недоступны на узле $node"
            return 1
        fi
        log "Узел $node имеет $gpu_count доступных GPU"
    done
    
    # Тестовый запуск пода с GPU
    log "Запуск тестового пода с GPU..."
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: gpu-test
  namespace: default
spec:
  containers:
  - name: gpu-test
    image: nvidia/cuda:12.8.0-base-ubuntu22.04
    command: ["nvidia-smi"]
    resources:
      limits:
        nvidia.com/gpu: 1
  restartPolicy: Never
EOF
    
    # Ожидание завершения тестового пода
    if ! kubectl wait --for=condition=complete pod/gpu-test --timeout=60s &>/dev/null; then
        log "Ошибка: Тестовый под с GPU не выполнился успешно"
        kubectl delete pod gpu-test &>/dev/null || true
        return 1
    fi
    
    # Проверка результата
    if ! kubectl logs gpu-test | grep -q "NVIDIA-SMI"; then
        log "Ошибка: GPU недоступен в тестовом поде"
        kubectl delete pod gpu-test &>/dev/null || true
        return 1
    fi
    
    kubectl delete pod gpu-test &>/dev/null || true
    log "Проверка GPU ресурсов успешно пройдена"
    return 0
}

# Функция установки предустановочных компонентов
install_prerequisites() {
    log "Установка предустановочных компонентов..."
    
    # Установка Ingress NGINX
    log "Установка Ingress NGINX..."
    if ! source "${SCRIPTS_SETUP_INGRESS_PATH}"; then
        log "Ошибка при установке Ingress NGINX"
        return 1
    fi
    
    # Установка Cert Manager
    log "Установка Cert Manager..."
    if ! source "${SCRIPTS_SETUP_CERT_MANAGER_PATH}"; then
        log "Ошибка при установке Cert Manager"
        return 1
    fi
    
    # Установка Local CA
    log "Установка Local CA..."
    if ! source "${SCRIPTS_SETUP_LOCAL_CA_PATH}"; then
        log "Ошибка при установке Local CA"
        return 1
    fi
    
    # Настройка DNS
    log "Настройка DNS..."
    if ! source "${SCRIPTS_SETUP_DNS_PATH}"; then
        log "Ошибка при настройке DNS"
        return 1
    fi
    
    log "Установка предустановочных компонентов завершена успешно"
    return 0
}

# Функция переустановки компонентов
reinstall_prerequisites() {
    log "Переустановка предустановочных компонентов..."
    
    # Удаление существующих компонентов
    log "Удаление существующих компонентов..."
    kubectl delete namespace ingress-nginx cert-manager &>/dev/null || true
    kubectl delete -f "${SCRIPTS_SETUP_LOCAL_CA_PATH}/manifests" &>/dev/null || true
    
    # Ожидание удаления namespace
    while kubectl get namespace ingress-nginx cert-manager &>/dev/null; do
        log "Ожидание удаления namespace..."
        sleep 5
    done
    
    # Установка новых компонентов
    if ! install_prerequisites; then
        log "Ошибка при переустановке компонентов"
        return 1
    fi
    
    log "Переустановка предустановочных компонентов завершена успешно"
    return 0
}

# Функция для установки прав выполнения
setup_executable_permissions() {
    local scripts=(
        "${SCRIPTS_ENV_PATH}"
        "${SCRIPTS_ASCII_BANNERS_PATH}"
        "${SCRIPTS_SETUP_WSL_PATH}"
        "${SCRIPTS_SETUP_BINS_PATH}"
        "${SCRIPTS_SETUP_KIND_PATH}"
        "${SCRIPTS_SETUP_INGRESS_PATH}"
        "${SCRIPTS_SETUP_CERT_MANAGER_PATH}"
        "${SCRIPTS_SETUP_DNS_PATH}"
        "${SCRIPTS_DASHBOARD_TOKEN_PATH}"
        "${SCRIPTS_CHARTS_PATH}"
        "${SCRIPTS_CONNECTIVITY_CHECK_PATH}"
    )

    echo "Установка прав выполнения для скриптов..."
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            chmod +x "$script"
        else
            echo "Предупреждение: Файл $script не найден"
        fi
    done
}

# Установка прав выполнения
setup_executable_permissions

# Функция проверки наличия необходимых утилит
check_dependencies() {
    local required_tools=("docker" "kind" "kubectl" "helm" "curl" "nc" "getent")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo "Ошибка: Утилита $tool не установлена"
            exit 1
        fi
    done
}

# Проверка наличия необходимых файлов конфигурации
required_files=(
    "${SCRIPTS_ENV_PATH}"
    "${SCRIPTS_ASCII_BANNERS_PATH}"
    "${SCRIPTS_SETUP_WSL_PATH}"
    "${SCRIPTS_SETUP_BINS_PATH}"
    "${SCRIPTS_SETUP_KIND_PATH}"
    "${SCRIPTS_SETUP_INGRESS_PATH}"
    "${SCRIPTS_SETUP_CERT_MANAGER_PATH}"
    "${SCRIPTS_SETUP_DNS_PATH}"
    "${SCRIPTS_DASHBOARD_TOKEN_PATH}"
    "${SCRIPTS_CHARTS_PATH}"
    "${SCRIPTS_CONNECTIVITY_CHECK_PATH}"
)

# Проверка существования всех необходимых файлов
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Ошибка: Не найден требуемый файл: $file"
        exit 1
    fi
done

# Проверка GPU в WSL2
check_wsl_gpu() {
    log "Проверка GPU в WSL2..."
    
    # Проверка nvidia-smi
    if ! command -v nvidia-smi &> /dev/null; then
        log "Ошибка: nvidia-smi не найден"
        return 1
    fi
    
    # Проверка версии драйвера
    local driver_version
    driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
    if ! awk -v v1="$driver_version" -v v2="535.104.05" 'BEGIN{if (v1 >= v2) exit 0; else exit 1}'; then
        log "Ошибка: Версия драйвера NVIDIA ($driver_version) ниже требуемой (535.104.05)"
        return 1
    fi
    
    # Проверка CUDA
    if ! command -v nvcc &> /dev/null; then
        log "Ошибка: CUDA toolkit не установлен"
        return 1
    fi
    
    local cuda_version
    cuda_version=$(nvcc --version | grep "release" | awk '{print $5}' | cut -d',' -f1)
    if ! awk -v v1="$cuda_version" -v v2="12.8" 'BEGIN{if (v1 >= v2) exit 0; else exit 1}'; then
        log "Ошибка: Версия CUDA ($cuda_version) ниже требуемой (12.8)"
        return 1
    fi
    
    log "Проверка GPU в WSL2 успешно пройдена"
    return 0
}

# Проверка тензорных операций
check_tensors() {
    log "Проверка поддержки тензорных операций..."
    
    # Создание тестового пода
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: tensor-test
  namespace: default
spec:
  containers:
  - name: tensor-test
    image: nvcr.io/nvidia/pytorch:23.12-py3
    command: ["python3", "-c", "
import torch
import time

# Проверка доступности CUDA
print('CUDA доступен:', torch.cuda.is_available())
print('Количество GPU:', torch.cuda.device_count())
print('Текущее GPU устройство:', torch.cuda.current_device())
print('Имя GPU устройства:', torch.cuda.get_device_name(0))

# Тест производительности
if torch.cuda.is_available():
    # Создание тензоров на GPU
    x = torch.randn(1000, 1000).cuda()
    y = torch.randn(1000, 1000).cuda()
    
    # Замер времени матричного умножения
    start = time.time()
    z = torch.matmul(x, y)
    torch.cuda.synchronize()
    end = time.time()
    
    print(f'Время выполнения: {(end-start)*1000:.2f} мс')
    print('Тест производительности пройден успешно')
"]
    resources:
      limits:
        nvidia.com/gpu: 1
  restartPolicy: Never
EOF

    # Ожидание создания пода
    if ! kubectl wait --for=condition=ready pod/tensor-test --timeout=60s &>/dev/null; then
        log "Ошибка: Тестовый под не запустился"
        kubectl delete pod tensor-test &>/dev/null || true
        return 1
    fi
    
    # Ожидание завершения пода
    if ! kubectl wait --for=condition=complete pod/tensor-test --timeout=120s &>/dev/null; then
        log "Ошибка: Тестовый под не завершился"
        kubectl logs tensor-test
        kubectl delete pod tensor-test &>/dev/null || true
        return 1
    fi
    
    # Анализ результатов
    local logs
    logs=$(kubectl logs tensor-test)
    
    if ! echo "$logs" | grep -q "CUDA доступен: True"; then
        log "Ошибка: CUDA недоступен для PyTorch"
        kubectl delete pod tensor-test &>/dev/null || true
        return 1
    fi
    
    if ! echo "$logs" | grep -q "Тест производительности пройден успешно"; then
        log "Ошибка: Тест производительности не пройден"
        kubectl delete pod tensor-test &>/dev/null || true
        return 1
    fi
    
    kubectl delete pod tensor-test &>/dev/null || true
    log "Проверка тензорных операций успешно пройдена"
    return 0
}

# Основной процесс
log "Начало проверки и развертывания..."

# Проверка GPU в WSL2
if ! check_wsl_gpu; then
    log "Ошибка: Проверка GPU в WSL2 не пройдена"
    exit 1
fi

# Проверка доступа к Kubernetes
if ! check_kubernetes_access; then
    log "Ошибка: Проверка доступа к Kubernetes не пройдена"
    exit 1
fi

# Проверка GPU в кластере
if ! check_cluster_gpu; then
    log "Ошибка: Проверка GPU в кластере не пройдена"
    exit 1
fi

# Проверка тензоров
if ! check_tensors; then
    log "Ошибка: Проверка тензорных операций не пройдена"
    exit 1
fi

# Если указан флаг --check-only, завершаем работу
if [ "$CHECK_ONLY" = true ]; then
    log "Все проверки успешно пройдены"
    exit 0
fi

# Если указан флаг --reinstall-core, переустанавливаем базовые компоненты
if [ "$REINSTALL_CORE" = true ]; then
    if ! reinstall_prerequisites; then
        log "Ошибка при переустановке базовых компонентов"
        exit 1
    fi
    exit 0
fi

# Установка базовых компонентов
if ! install_prerequisites; then
    log "Ошибка при установке базовых компонентов"
    exit 1
fi

# Развертывание приложений
log "Развертывание приложений..."
if ! "${SCRIPTS_CHARTS_PATH}/src/charts.sh" install all; then
    log "Ошибка при развертывании приложений"
    exit 1
fi




# Проверка доступности сервисов
log "Проверка доступности сервисов..."
if ! source "${SCRIPTS_CONNECTIVITY_CHECK_PATH}"; then
    log "Ошибка при проверке доступности сервисов"
    exit 1
fi

log "Развертывание успешно завершено!"