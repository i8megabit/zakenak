#!/bin/bash

set -e

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Обработка аргументов командной строки
USE_PROD_VALUES=false
for arg in "$@"; do
    case $arg in
        --prod)
            USE_PROD_VALUES=true
            shift
            ;;
    esac
done

log_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

handle_error() {
    log_error "$1"
    exit 1
}

log_info "Настраиваю внешний Ollama с поддержкой GPU для Kubernetes"
echo "Этот скрипт поможет запустить Ollama в Docker и подключить его к Kubernetes."

# Проверяем, установлен ли Docker
if ! command -v docker &> /dev/null; then
    handle_error "Docker не установлен. Сначала установите Docker."
fi

# Проверяем, установлен ли Docker Compose
if ! docker compose version &> /dev/null; then
    handle_error "Docker Compose V2 не установлен. Поставьте его заранее."
fi

# Проверяем, установлен ли kubectl
if ! command -v kubectl &> /dev/null; then
    handle_error "kubectl не найден. Установите его сначала."
fi

# Проверяем, установлен ли Helm
if ! command -v helm &> /dev/null; then
    handle_error "Helm не установлен. Поставьте его." 
fi

# Проверяем наличие NVIDIA Container Toolkit
log_warn "Проверяю, установлен ли NVIDIA Container Toolkit..."
if ! command -v nvidia-smi &> /dev/null; then
    handle_error "Драйверы NVIDIA не установлены. Поставьте их сначала."
fi

if ! command -v nvidia-container-cli &> /dev/null; then
    log_warn "NVIDIA Container Toolkit не найден. Устанавливаю..."
    
    # Установка NVIDIA Container Toolkit
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    if ! curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -; then
        handle_error "Не удалось добавить GPG ключ NVIDIA"
    fi
    
    if ! curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list; then
        handle_error "Не удалось добавить репозиторий NVIDIA"
    fi
    
    if ! sudo apt-get update; then
        handle_error "Не удалось обновить список пакетов"
    fi
    
    if ! sudo apt-get install -y nvidia-container-toolkit; then
        handle_error "Не удалось установить NVIDIA Container Toolkit"
    fi
    
    # Настройка Docker для работы с NVIDIA Container Toolkit
    if ! sudo nvidia-ctk runtime configure --runtime=docker; then
        handle_error "Не удалось настроить Docker под NVIDIA"
    fi
    
    if ! sudo systemctl restart docker; then
        handle_error "Не удалось перезапустить сервис Docker"
    fi
    
    log_info "NVIDIA Container Toolkit установлен и настроен"
else
    log_info "NVIDIA Container Toolkit уже установлен"
fi

# Запускаем контейнер Ollama с поддержкой GPU
log_warn "Запуск контейнера Ollama с поддержкой GPU..."
if [ ! -d "docker-compose" ]; then
    handle_error "Не найдена папка docker-compose. Проверьте текущую директорию."
fi

cd docker-compose
if ! docker compose up -d; then
    handle_error "Не удалось запустить контейнер Ollama. Смотрите логи docker-compose."
fi
cd ..

# Ждём запуска Ollama
log_warn "Ожидание старта Ollama..."
sleep 5

# Проверяем, запустился ли Ollama
MAX_RETRIES=12
RETRY_COUNT=0
OLLAMA_READY=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s http://localhost:11434/api/tags &> /dev/null; then
        OLLAMA_READY=true
        break
    fi
    
    log_warn "Ожидание старта Ollama... ($(($RETRY_COUNT + 1))/$MAX_RETRIES)"
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 5
done

if [ "$OLLAMA_READY" = false ]; then
    log_error "Ollama не запустился вовремя. Проверьте логи Docker:"
    echo "docker logs ollama"
    echo "Если видите ошибки про GPU, убедитесь, что драйверы NVIDIA и toolkit установлены"
    exit 1
fi

log_info "Ollama запущен с поддержкой GPU"

# Создаём namespace, если его ещё нет
if ! kubectl get namespace prod &> /dev/null; then
    log_warn "Создаю namespace 'prod'..."
    if ! kubectl create namespace prod; then
    handle_error "Не удалось создать namespace 'prod'"
    fi
    log_info "Namespace 'prod' успешно создан"
else
    log_info "Namespace 'prod' уже существует"
fi

# Создаём сервис Kubernetes для внешнего Ollama
log_warn "Создаю сервис Kubernetes для внешнего Ollama..."
if ! kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ollama
  namespace: prod
  labels:
    app: ollama
spec:
  type: ExternalName
  externalName: host.docker.internal
  ports:
    - port: 11434
      targetPort: 11434
      protocol: TCP
      name: http
EOF
then
    handle_error "Не удалось создать сервис Ollama"
fi

# Проверяем, что сервис создан
if ! kubectl get service ollama -n prod &> /dev/null; then
    handle_error "Сервис Ollama не создан. Посмотрите kubectl logs"
fi

log_info "Сервис Ollama создан"

# Проверяем подключение к Ollama из Kubernetes
log_warn "Проверяю подключение к Ollama из Kubernetes..."
if ! kubectl run -it --rm --restart=Never debug --image=curlimages/curl -- curl -s --connect-timeout 5 http://ollama.prod.svc.cluster.local:11434/api/tags &> /dev/null; then
    log_warn "Не удалось подключиться к Ollama из Kubernetes"
    log_warn "Возможно, есть сетевые проблемы между Kubernetes и Docker-хостом"
    log_warn "Проверьте, что host.docker.internal резолвится внутри кластера"
    log_warn "При использовании Kind или Minikube может потребоваться доп. конфигурация"
    log_warn "Продолжаю установку, но Open WebUI может не подключиться к Ollama"
else
    log_info "Подключение к Ollama из Kubernetes успешно"
fi

# Деплой чарта Open WebUI
log_warn "Разворачиваю Helm chart Open WebUI..."
if [ "$USE_PROD_VALUES" = true ]; then
    log_info "Использую продовые значения (values.prod.yaml)"
    if ! helm upgrade --install open-webui ./helm-charts/open-webui -n prod -f ./helm-charts/open-webui/values.prod.yaml --set deployment.gpuConfig=false; then
    handle_error "Не удалось установить Helm chart Open WebUI"
    fi
else
    if ! helm upgrade --install open-webui ./helm-charts/open-webui -n prod --set deployment.gpuConfig=false; then
        handle_error "Failed to deploy Open WebUI Helm chart."
    fi
fi

  log_warn "Ждём запуска Open WebUI (может занять до часа)..."
  log_warn "Startup probe допускает до 60 минут на готовность контейнера"

# Ожидание готовности пода Open WebUI (с тайм-аутом)
timeout=3600  # 60 minutes (to match the increased startup probe configuration)
start_time=$(date +%s)
pod_ready=false

while true; do
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    
    if [ $elapsed -gt $timeout ]; then
          log_error "Время ожидания готовности Open WebUI истекло"
          log_warn "Проверьте статус пода командами:"
          log_warn "kubectl get pods -n prod"
          log_warn "kubectl describe pod -n prod -l app=open-webui"
          log_warn "kubectl logs -n prod -l app=open-webui"
        break
    fi
    
    pod_status=$(kubectl get pods -n prod -l app=open-webui -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
    
    if [ "$pod_status" == "Running" ]; then
        ready_status=$(kubectl get pods -n prod -l app=open-webui -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
        if [ "$ready_status" == "true" ]; then
            log_info "Open WebUI is running and ready!"
            pod_ready=true
            break
        fi
    fi
    
      # Проверяем падения контейнера
    restart_count=$(kubectl get pods -n prod -l app=open-webui -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}' 2>/dev/null || echo "0")
    # Ensure restart_count is a valid integer
    if [[ ! "$restart_count" =~ ^[0-9]+$ ]]; then
        restart_count=0
    fi

    if [ $restart_count -gt 3 ]; then
          log_error "Контейнер Open WebUI падал несколько раз. Смотрим логи..."
        kubectl logs -n prod -l app=open-webui
          log_warn "Возможно, нужно увеличить лимиты памяти или искать другие проблемы"
    fi
    
      log_warn "Ожидание готовности Open WebUI... (${elapsed}s)"
    sleep 10
done

if [ "$pod_ready" = true ]; then
  log_info "Установка завершена!"
  echo -e "Открывайте Open WebUI по адресу: ${YELLOW}http://webui.prod.local${NC}"
  echo -e "Добавьте запись в /etc/hosts:" 
  echo -e "${YELLOW}127.0.0.1 webui.prod.local${NC}"
  echo -e "Чтобы проверить соединение из Kubernetes, выполните:" 
  echo -e "${YELLOW}kubectl run -it --rm debug --image=curlimages/curl -- curl http://host.docker.internal:11434/api/tags${NC}"
  echo -e "Логи Open WebUI можно посмотреть командой:" 
  echo -e "${YELLOW}kubectl logs -n prod -l app=open-webui${NC}"
else
  log_warn "Установка завершена с предупреждениями. Open WebUI может быть не готов"
  echo -e "Попробуйте открыть Open WebUI: ${YELLOW}http://webui.prod.local${NC}"
  echo -e "Добавьте запись в /etc/hosts:" 
  echo -e "${YELLOW}127.0.0.1 webui.prod.local${NC}"
  echo -e "Советы по диагностике:" 
  echo -e "1. Проверить Ollama: ${YELLOW}docker logs ollama${NC}"
  echo -e "2. Проверить сервис: ${YELLOW}kubectl get svc -n prod ollama${NC}"
  echo -e "3. Проверить под: ${YELLOW}kubectl describe pod -n prod -l app=open-webui${NC}"
  echo -e "4. Логи Open WebUI: ${YELLOW}kubectl logs -n prod -l app=open-webui${NC}"
  echo -e "5. Проверить сеть: ${YELLOW}kubectl run -it --rm debug --image=curlimages/curl -- curl http://host.docker.internal:11434/api/tags${NC}"
  echo -e "6. Посмотреть логи Docker Compose: ${YELLOW}cd docker-compose && docker compose logs${NC}"
fi