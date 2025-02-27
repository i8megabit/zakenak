#!/usr/bin/bash
# Загрузка переменных окружения и баннеров
export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export TOOLS_DIR="${BASE_DIR}/tools/k8s-kind-setup"
export SCRIPTS_ENV_PATH="${TOOLS_DIR}/env/src/env.sh"

# Определение цветов для вывода
export RED="\033[0;31m"
export GREEN="\033[0;32m"
export YELLOW="\033[1;33m"
export CYAN="\033[0;36m"
export BLUE="\033[0;34m"
export NC="\033[0m" # No Color

# Функция вывода справки
show_help() {
    echo -e "${CYAN}Использование:${NC} $0 ${YELLOW}[ОПЦИИ]${NC}"
    echo ""
    echo -e "${CYAN}Опции:${NC}"
    echo -e "${GREEN}  --no-wsl              ${YELLOW}-${NC} Пропустить настройку WSL"
    echo -e "${GREEN}  --skip-gpu-check      ${YELLOW}-${NC} Пропустить проверку GPU"
    echo -e "${GREEN}  --skip-k8s-check      ${YELLOW}-${NC} Пропустить проверку доступа к Kubernetes"
    echo -e "${GREEN}  --skip-tensor-check   ${YELLOW}-${NC} Пропустить проверку тензорных операций"
    echo -e "${GREEN}  --check-only          ${YELLOW}-${NC} Только выполнить проверки без установки"
    echo -e "${GREEN}  --reinstall-core      ${YELLOW}-${NC} Переустановить базовые компоненты"
    echo -e "${GREEN}  --reinstall-ingress   ${YELLOW}-${NC} Переустановить только ingress-контроллер"
    echo -e "${GREEN}  --auto-install        ${YELLOW}-${NC} Автоматически устанавливать недостающие компоненты"
    echo -e "${GREEN}  --force-recreate      ${YELLOW}-${NC} Полное пересоздание кластера, затирая предыдущий"
    echo -e "${GREEN}  --run                 ${YELLOW}-${NC} Запустить базовую установку"
    echo -e "${GREEN}  --skip-charts         ${YELLOW}-${NC} Пропустить установку чартов"
    echo -e "${GREEN}  --debug               ${YELLOW}-${NC} Включить подробный режим отладки"
    echo -e "${GREEN}  --help                ${YELLOW}-${NC} Показать эту справку"
    echo ""
    exit 0
}

# Парсинг аргументов командной строки
SKIP_WSL=false
SKIP_GPU_CHECK=false
SKIP_K8S_CHECK=false
SKIP_TENSOR_CHECK=false
CHECK_ONLY=false
REINSTALL_CORE=false
REINSTALL_INGRESS=false
AUTO_INSTALL=false
FORCE_RECREATE=false
DEBUG=false
RUN=false
SKIP_CHARTS=false

# Если нет аргументов, показываем справку
if [ $# -eq 0 ]; then
    source "${SCRIPTS_ENV_PATH}"
    export SKIP_BANNER_MAIN=true
    source "${SCRIPTS_ASCII_BANNERS_PATH}"
    show_deploy_banner
    show_help
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-wsl)
            SKIP_WSL=true
            shift
            ;;
        --skip-gpu-check)
            SKIP_GPU_CHECK=true
            shift
            ;;
        --skip-k8s-check)
            SKIP_K8S_CHECK=true
            shift
            ;;
        --skip-tensor-check)
            SKIP_TENSOR_CHECK=true
            shift
            ;;
        --check-only)
            CHECK_ONLY=true
            shift
            ;;
        --reinstall-core)
            REINSTALL_CORE=true
            shift
            ;;
        --reinstall-ingress)
            REINSTALL_INGRESS=true
            shift
            ;;
        --auto-install)
            AUTO_INSTALL=true
            shift
            ;;
        --force-recreate)
            FORCE_RECREATE=true
            shift
            ;;
        --run)
            RUN=true
            shift
            ;;
        --skip-charts)
            SKIP_CHARTS=true
            shift
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Неизвестный параметр: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done



source "${SCRIPTS_ENV_PATH}"
export SKIP_BANNER_MAIN=true
source "${SCRIPTS_ASCII_BANNERS_PATH}"

show_deploy_banner

# Функция для логирования
log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${CYAN}$1${NC}"
}

# Функция для отладочного логирования
debug_log() {
    if [[ "$DEBUG" == "true" ]]; then
        echo -e "[DEBUG][$(date +'%Y-%m-%d %H:%M:%S')] ${NC}$1${NC}"
    fi
}

# Функция отката изменений при ошибке
rollback_changes() {
    log "Ошибка при настройке кластера. Выполняется откат изменений..."
    
    # Удаление кластера
    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        log "Удаление кластера ${CLUSTER_NAME}..."
        kind delete cluster --name "${CLUSTER_NAME}"
    fi
    
    # Очистка Docker ресурсов
    log "Очистка Docker ресурсов..."
    if docker ps -aq &>/dev/null; then
        docker stop $(docker ps -aq) 2>/dev/null || true
        docker rm $(docker ps -aq) 2>/dev/null || true
    fi
    
    # Удаление неиспользуемых сетей
    docker network prune -f &>/dev/null || true
    
    # Очистка системы Docker
    docker system prune -f &>/dev/null || true
    
    log "Откат изменений завершен"
}

# Проверка конфигурации Kubernetes и доступа charts.sh
check_kubernetes_access() {
    log "Проверка доступа к Kubernetes API..."
    
    # Если указан флаг --force-recreate, удаляем существующий кластер
    if [[ "$FORCE_RECREATE" == "true" ]]; then
        log "Принудительное пересоздание кластера..."
        if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
            log "Удаление существующего кластера ${CLUSTER_NAME}..."
            kind delete cluster --name "${CLUSTER_NAME}"
            # Ожидание удаления кластера
            sleep 5
        fi
    fi
    
    # Проверка конфигурации kubectl
    if ! kubectl cluster-info &>/dev/null; then
        log "Ошибка: Нет доступа к кластеру Kubernetes"
        if [[ "$AUTO_INSTALL" == "true" ]]; then
            log "Попытка настройки кластера Kubernetes..."
            
            # Установка необходимых бинарных компонентов (kubectl, kind, helm)
            log "Установка необходимых бинарных компонентов..."
            if ! source "${SCRIPTS_SETUP_BINS_PATH}"; then
                log "Ошибка при установке необходимых компонентов"
                return 1
            fi
            
            debug_log "Запуск скрипта настройки kind"
            # Ensure AUTO_INSTALL is exported to setup-kind.sh
            export AUTO_INSTALL
            export FORCE_RECREATE
            if ! source "${SCRIPTS_SETUP_KIND_PATH}"; then
                log "Ошибка при настройке кластера Kubernetes"
                rollback_changes
                return 1
            fi
            if ! kubectl cluster-info &>/dev/null; then
                log "Ошибка: Не удалось настроить доступ к кластеру Kubernetes"
                rollback_changes
                return 1
            fi
            log "Кластер Kubernetes успешно настроен"
        else
            return 1
        fi
    fi
    
    debug_log "Информация о кластере: $(kubectl cluster-info)"
    
    # Проверка прав доступа для charts.sh
    if ! kubectl auth can-i create deployments &>/dev/null; then
        log "Ошибка: Недостаточно прав для управления кластером"
        return 1
    fi
    
    # Проверка доступа к Helm
    if ! helm list &>/dev/null; then
        log "Ошибка: Нет доступа к Helm"
        if [[ "$AUTO_INSTALL" == "true" ]]; then
            log "Установка Helm..."
            curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
            if ! helm list &>/dev/null; then
                log "Ошибка: Не удалось установить Helm"
                return 1
            fi
            log "Helm успешно установлен"
        else
            return 1
        fi
    fi
    
    debug_log "Список релизов Helm: $(helm list -A)"
    
    log "Проверка доступа к Kubernetes API успешно пройдена"
    return 0
}

# Проверка GPU ресурсов в кластере
check_cluster_gpu() {
    # Если GPU не включен, пропускаем проверку
    if [[ "$GPU_ENABLED" == "false" ]]; then
        log "Режим CPU: пропуск проверки GPU ресурсов"
        return 0
    fi

    log "Проверка GPU ресурсов в кластере..."
    
    # Проверка наличия GPU узлов
    local gpu_nodes
    gpu_nodes=$(kubectl get nodes -l nvidia.com/gpu=true -o name)
    if [[ -z "$gpu_nodes" ]]; then
        log "Ошибка: GPU узлы не найдены в кластере"
        if [[ "$AUTO_INSTALL" == "true" ]]; then
            log "Попытка настройки GPU в кластере..."
            debug_log "Установка NVIDIA device plugin"
            kubectl create namespace gpu-operator || true
            helm repo add nvidia https://helm.ngc.nvidia.com/nvidia || true
            helm repo update
            helm install --wait --generate-name \
                -n gpu-operator \
                nvidia/gpu-operator \
                --set driver.enabled=false
            
            # Проверка установки
            gpu_nodes=$(kubectl get nodes -l nvidia.com/gpu=true -o name)
            if [[ -z "$gpu_nodes" ]]; then
                log "Ошибка: Не удалось настроить GPU узлы в кластере"
                return 1
            fi
            log "GPU узлы успешно настроены в кластере"
        else
            return 1
        fi
    fi
    debug_log "Найдены GPU узлы: $gpu_nodes"
    log "Найдены GPU узлы: $gpu_nodes"
    
    # Проверка статуса NVIDIA device plugin
    local plugin_pods
    # First check in kube-system namespace (default location)
    plugin_pods=$(kubectl get pods -n kube-system -l k8s-app=nvidia-device-plugin-daemonset -o name 2>/dev/null || true)
    if [[ -z "$plugin_pods" ]]; then
        # If not found in kube-system, check in all namespaces
        debug_log "NVIDIA device plugin не найден в kube-system, проверка во всех namespace..."
        plugin_pods=$(kubectl get pods --all-namespaces -l k8s-app=nvidia-device-plugin-daemonset -o name 2>/dev/null || true)
        
        if [[ -z "$plugin_pods" ]]; then
            log "Ошибка: NVIDIA device plugin не запущен"
            if [[ "$AUTO_INSTALL" == "true" ]]; then
                log "Установка NVIDIA device plugin..."
                # Delete existing DaemonSet if it exists to ensure the new configuration is applied
                kubectl delete daemonset nvidia-device-plugin-daemonset -n kube-system --ignore-not-found=true
                # Apply our custom manifest instead of the one from GitHub
                kubectl apply -f "${TOOLS_DIR}/nvidia-device-plugin-custom.yml"
                
                # Wait a moment for the pods to be created
                sleep 5
                
                # Check again in all namespaces
                plugin_pods=$(kubectl get pods --all-namespaces -l k8s-app=nvidia-device-plugin-daemonset -o name 2>/dev/null || true)
                if [[ -z "$plugin_pods" ]]; then
                    # Additional debugging
                    debug_log "Проверка всех подов в kube-system: $(kubectl get pods -n kube-system)"
                    debug_log "Проверка всех DaemonSets: $(kubectl get ds --all-namespaces)"
                    log "Предупреждение: Не удалось установить NVIDIA device plugin"
                    # Не выходим с ошибкой, продолжаем выполнение
                    return 0
                fi
                log "NVIDIA device plugin успешно установлен"
            else
                return 1
            fi
        else
            debug_log "NVIDIA device plugin найден в другом namespace"
        fi
    fi
    debug_log "NVIDIA device plugin поды: $plugin_pods"
    
    # Get the namespace from the pod name
    local plugin_namespace
    if [[ "$plugin_pods" == pod/* ]]; then
        # If the format is pod/name
        plugin_namespace="default"
    elif [[ "$plugin_pods" == */pod/* ]]; then
        # If the format is namespace/pod/name
        plugin_namespace=$(echo "$plugin_pods" | cut -d'/' -f1)
    else
        # Default to kube-system
        plugin_namespace="kube-system"
    fi
    debug_log "NVIDIA device plugin namespace: $plugin_namespace"
    
    # Проверка статуса подов device plugin с учетом правильного namespace
    if ! kubectl wait --for=condition=ready pods -n "$plugin_namespace" -l k8s-app=nvidia-device-plugin-daemonset --timeout=60s &>/dev/null; then
        log "Предупреждение: NVIDIA device plugin поды не готовы"
        debug_log "Статус подов: $(kubectl get pods -n "$plugin_namespace" -l k8s-app=nvidia-device-plugin-daemonset -o wide)"
        # Не выходим с ошибкой, продолжаем выполнение
        return 0
    fi
    
    # Проверка доступности GPU ресурсов
    for node in $gpu_nodes; do
        local gpu_count
        gpu_count=$(kubectl get $node -o jsonpath='{.status.allocatable.nvidia\.com/gpu}')
        if [[ -z "$gpu_count" || "$gpu_count" -eq "0" ]]; then
            log "Предупреждение: GPU ресурсы недоступны на узле $node"
            debug_log "Allocatable ресурсы: $(kubectl get $node -o jsonpath='{.status.allocatable}')"
            # Не выходим с ошибкой, продолжаем выполнение
            return 0
        fi
        debug_log "Узел $node имеет $gpu_count доступных GPU"
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
        log "Предупреждение: Тестовый под с GPU не выполнился успешно"
        debug_log "Статус пода: $(kubectl get pod gpu-test -o wide)"
        debug_log "Логи пода: $(kubectl logs gpu-test)"
        kubectl delete pod gpu-test &>/dev/null || true
        # Не выходим с ошибкой, продолжаем выполнение
        return 0
    fi
    
    # Проверка результата
    if ! kubectl logs gpu-test | grep -q "NVIDIA-SMI"; then
        log "Предупреждение: GPU недоступен в тестовом поде"
        debug_log "Логи пода: $(kubectl logs gpu-test)"
        kubectl delete pod gpu-test &>/dev/null || true
        # Не выходим с ошибкой, продолжаем выполнение
        return 0
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

# Функция переустановки ingress-контроллера
reinstall_ingress() {
    log "Переустановка ingress-контроллера..."
    
    # Удаление существующего ingress-контроллера
    log "Удаление существующего ingress-контроллера..."
    kubectl delete namespace ingress-nginx &>/dev/null || true
    
    # Ожидание удаления namespace
    while kubectl get namespace ingress-nginx &>/dev/null; do
        log "Ожидание удаления namespace ingress-nginx..."
        sleep 5
    done
    
    # Установка нового ingress-контроллера
    log "Установка нового ingress-контроллера..."
    if ! source "${SCRIPTS_SETUP_INGRESS_PATH}"; then
        log "Ошибка при установке ingress-контроллера"
        return 1
    fi
    
    log "Переустановка ingress-контроллера завершена успешно"
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
    if ! nvidia-smi &> /dev/null; then
        log "Ошибка: nvidia-smi не найден"
        if [[ "$AUTO_INSTALL" == "true" ]]; then
            log "Попытка установки драйверов NVIDIA..."
            debug_log "Установка драйверов NVIDIA для WSL2"
            sudo apt-get update && sudo apt-get install -y nvidia-driver-535 nvidia-utils-535
            if ! nvidia-smi &> /dev/null; then
                log "Ошибка: Не удалось установить драйверы NVIDIA"
                return 1
            fi
            log "Драйверы NVIDIA успешно установлены"
        else
            return 1
        fi
    fi
    
    # Проверка версии драйвера
    local driver_version
    driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
    debug_log "Текущая версия драйвера NVIDIA: $driver_version"
    if ! awk -v v1="$driver_version" -v v2="535.104.05" 'BEGIN{if (v1 >= v2) exit 0; else exit 1}'; then
        log "Ошибка: Версия драйвера NVIDIA ($driver_version) ниже требуемой (535.104.05)"
        if [[ "$AUTO_INSTALL" == "true" ]]; then
            log "Попытка обновления драйверов NVIDIA..."
            sudo apt-get update && sudo apt-get install -y --only-upgrade nvidia-driver-535 nvidia-utils-535
            driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
            if ! awk -v v1="$driver_version" -v v2="535.104.05" 'BEGIN{if (v1 >= v2) exit 0; else exit 1}'; then
                log "Ошибка: Не удалось обновить драйверы NVIDIA до требуемой версии"
                return 1
            fi
            log "Драйверы NVIDIA успешно обновлены до версии $driver_version"
        else
            return 1
        fi
    fi
    
    log "Проверка GPU в WSL2 успешно пройдена"
    return 0
}

# Проверка тензорных операций
check_tensors() {
    # If GPU not enabled, skip tensor check
    if [[ "$GPU_ENABLED" == "false" ]]; then
        log "Режим CPU: пропуск проверки тензорных операций"
        return 0
    fi

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

# Вывод информации о режиме отладки
if [[ "$DEBUG" == "true" ]]; then
    debug_log "Режим отладки включен"
    debug_log "Параметры запуска:"
    debug_log "  SKIP_WSL=$SKIP_WSL"
    debug_log "  SKIP_GPU_CHECK=$SKIP_GPU_CHECK"
    debug_log "  SKIP_K8S_CHECK=$SKIP_K8S_CHECK"
    debug_log "  SKIP_TENSOR_CHECK=$SKIP_TENSOR_CHECK"
    debug_log "  CHECK_ONLY=$CHECK_ONLY"
    debug_log "  REINSTALL_CORE=$REINSTALL_CORE"
    debug_log "  REINSTALL_INGRESS=$REINSTALL_INGRESS"
    debug_log "  AUTO_INSTALL=$AUTO_INSTALL"
    debug_log "  FORCE_RECREATE=$FORCE_RECREATE"
    debug_log "  SKIP_CHARTS=$SKIP_CHARTS"
    debug_log "  RUN=$RUN"
fi

# Проверка GPU в WSL2
if [[ "$SKIP_GPU_CHECK" != "true" ]]; then
    if ! check_wsl_gpu; then
        log "Ошибка: Проверка GPU в WSL2 не пройдена"
        exit 1
    fi
else
    log "Проверка GPU в WSL2 пропущена"
fi

# Проверка доступа к Kubernetes
if [[ "$SKIP_K8S_CHECK" != "true" ]]; then
    if ! check_kubernetes_access; then
        log "Ошибка: Проверка доступа к Kubernetes не пройдена"
        exit 1
    fi
else
    log "Проверка доступа к Kubernetes пропущена"
fi

# Проверка GPU в кластере
if [[ "$SKIP_GPU_CHECK" != "true" ]]; then
    if ! check_cluster_gpu; then
        log "Ошибка: Проверка GPU в кластере не пройдена"
        exit 1
    fi
else
    log "Проверка GPU в кластере пропущена"
fi

# Проверка тензоров
if [[ "$SKIP_TENSOR_CHECK" != "true" ]]; then
    if ! check_tensors; then
        log "Ошибка: Проверка тензорных операций не пройдена"
        exit 1
    fi
else
    log "Проверка тензорных операций пропущена"
fi

# Если указан флаг --check-only, завершаем работу
if [[ "$CHECK_ONLY" == "true" ]]; then
    log "Все проверки успешно пройдены"
    exit 0
fi

# Если указан флаг --reinstall-core, переустанавливаем базовые компоненты
if [[ "$REINSTALL_CORE" == "true" ]]; then
    if ! reinstall_prerequisites; then
        log "Ошибка при переустановке базовых компонентов"
        exit 1
    fi
    log "Базовые компоненты успешно переустановлены"
    exit 0
fi

# Если указан флаг --reinstall-ingress, переустанавливаем только ingress-контроллер
if [[ "$REINSTALL_INGRESS" == "true" ]]; then
    if ! reinstall_ingress; then
        log "Ошибка при переустановке ingress-контроллера"
        exit 1
    fi
    log "Ingress-контроллер успешно переустановлен"
    exit 0
fi

# Если указан флаг --run, выполняем базовую установку
if [[ "$RUN" == "true" ]]; then
    # Установка базовых компонентов
    if ! install_prerequisites; then
        log "Ошибка при установке базовых компонентов"
        rollback_changes
        exit 1
    fi

    # Установка NVIDIA device plugin если GPU включен
    if [[ "$GPU_ENABLED" == "true" ]]; then
        log "Установка NVIDIA device plugin..."
        if ! "${SCRIPTS_CHARTS_PATH}/src/charts.sh" install nvidia-device-plugin -n kube-system; then
            log "Предупреждение: Не удалось установить NVIDIA device plugin"
            # Не выходим с ошибкой, продолжаем выполнение
        fi
    else
        log "Режим CPU: пропуск установки NVIDIA device plugin"
    fi

    log "Базовая установка кластера успешно завершена!"
    log "Для установки чартов используйте команду: ${SCRIPTS_CHARTS_PATH}/src/charts.sh install all"
fi