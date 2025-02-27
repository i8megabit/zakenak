# Руководство по использованию Docker в Zakenak

```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

Should Harbour?	No.
```

## Навигация
- [Главная страница](../README.md)
- Документация
  - [Руководство по развертыванию](DEPLOYMENT.md)
  - [GitOps подход](GITOPS.md)
  - [API Reference](api.md)
  - [Устранение неполадок](troubleshooting.md)
  - [GPU в WSL2](GPU-WSL.md)
  - [Использование Docker](DOCKER-USAGE.md) (текущий документ)
  - [Настройка KUBECONFIG](KUBECONFIG.md)
  - [Мониторинг](MONITORING.md)
  - [Настройка сети](NETWORK-CONFIGURATION.md)
- [Примеры](../examples/README.md)

## Содержание
1. [Подготовка окружения](#подготовка-окружения)
2. [Использование образа](#использование-образа)
3. [Конфигурация](#конфигурация)
4. [GPU оптимизация](#gpu-оптимизация)
5. [Примеры использования](#примеры-использования)
6. [Переменные окружения](#переменные-окружения)
7. [Монтирование томов](#монтирование-томов)
8. [Безопасность](#безопасность)
9. [Устранение неполадок](#устранение-неполадок)

## Подготовка окружения

### Системные требования
- Windows 11 Pro/Enterprise или Linux
- WSL2 с Ubuntu 22.04 (для Windows)
- Docker Desktop с WSL2 бэкендом (для Windows)
- NVIDIA Container Toolkit
- CUDA Toolkit 12.8+
- Минимум 16GB RAM
- NVIDIA GPU (Compute Capability 7.0+)

### Быстрая установка
```bash
# Установка NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Настройка container runtime
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### Проверка установки
```bash
# Базовая проверка Docker
docker info

# Проверка GPU поддержки
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi

# Проверка CUDA в контейнере
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi -L
```

## Использование образа

### Получение образа
```bash
# Рекомендуемый способ (фиксированная версия)
docker pull ${ZAKENAK_IMAGE}:${ZAKENAK_VERSION}

# Последняя версия (не рекомендуется для production)
docker pull ${ZAKENAK_IMAGE}:latest
```

### Базовое использование

```bash
# Стандартный запуск
docker run --gpus all \
    -v $(pwd):/workspace \
    -v ${KUBECONFIG%/*}:/root/.kube \
    --network host \
    ${ZAKENAK_IMAGE}:${ZAKENAK_VERSION} converge

# Запуск с дополнительными параметрами
docker run --gpus all \
    -v $(pwd):/workspace \
    -v ${KUBECONFIG%/*}:/root/.kube \
    -e NVIDIA_VISIBLE_DEVICES=all \
    -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    ${ZAKENAK_IMAGE}:${ZAKENAK_VERSION} \
    --config /workspace/zakenak.yaml \
    converge

```

## Конфигурация

### Структура zakenak.yaml
```yaml
version: "1.0"
project: myapp
environment: prod

registry:
  url: registry.local
  username: ${REGISTRY_USER}
  password: ${REGISTRY_PASS}
  insecure: false

deploy:
  namespace: prod
  charts:
    - name: cert-manager
      path: ./helm-charts/cert-manager
      values:
        - values.yaml
        - values-prod.yaml
    - name: ollama
      path: ./helm-charts/ollama
      values:
        - values-gpu.yaml

build:
  context: .
  dockerfile: Dockerfile
  args:
    VERSION: v1.0.0
  gpu:
    enabled: true
    runtime: nvidia
    memory: "8Gi"
    devices: "all"
    capabilities:
      - compute
      - utility

security:
  rbac:
    enabled: true
    serviceAccount: zakenak
  networkPolicies:
    enabled: true
  podSecurityContext:
    runAsNonRoot: true
    runAsUser: 1000
```

## GPU оптимизация

> Для подробной информации о настройке и использовании GPU в WSL2 см. [GPU в WSL2](GPU-WSL.md).

### Настройка производительности
```bash
# Ограничение памяти GPU
docker run --gpus all \
    -e GPU_MEMORY_FRACTION=0.8 \
    ghcr.io/i8megabit/zakenak:1.0.0 converge

# Multi-GPU конфигурация
docker run --gpus '"device=0,1"' \
    -e GPU_SPLIT_MODE="balanced" \
    ghcr.io/i8megabit/zakenak:1.0.0 converge
```

## Примеры использования

### Развертывание компонентов
```bash
# Установка Ollama с GPU
docker run --gpus all \
    -v $(pwd):/workspace \
    -v ~/.kube:/root/.kube \
    ghcr.io/i8megabit/zakenak:1.0.0 \
    deploy --chart ./helm-charts/ollama \
    --values ./helm-charts/ollama/values-gpu.yaml
```

### Мониторинг
```bash
# GPU метрики
docker run --gpus all \
    ghcr.io/i8megabit/zakenak:1.0.0 \
    nvidia-smi dmon -s pucvmet

# Отладка
docker run --gpus all \
    -v $(pwd):/workspace \
    -e ZAKENAK_DEBUG=true \
    ghcr.io/i8megabit/zakenak:1.0.0 converge
```

## Переменные окружения

| Переменная | Описание | По умолчанию |
|------------|-----------|--------------|
| `KUBECONFIG` | Путь к kubeconfig | `~/.kube/config` |
| `ZAKENAK_DEBUG` | Режим отладки | `false` |
| `NVIDIA_VISIBLE_DEVICES` | Доступные GPU | `all` |
| `GPU_MEMORY_FRACTION` | Лимит памяти GPU | `0.9` |
| `GPU_SPLIT_MODE` | Режим Multi-GPU | `exclusive` |

## Монтирование томов

### Основные точки монтирования
- `/workspace`: Рабочая директория (обязательно)
- `~/.kube`: Kubernetes конфигурация (обязательно)
- `~/.cache/zakenak`: Кэш (опционально)
- `/var/run/docker.sock`: Docker daemon (опционально)

## Безопасность

### Базовая защита контейнеров
```bash
# Безопасный запуск с полным набором ограничений
docker run --gpus all \
    --read-only \
    --security-opt=no-new-privileges \
    --security-opt seccomp=${DEFAULT_SECURITY_PROFILE} \
    --cap-drop ALL \
    --cap-add SYS_ADMIN \
    --pids-limit ${DEFAULT_PIDS_LIMIT} \
    --cpus ${DEFAULT_CPU_LIMIT} \
    --memory ${DEFAULT_MEMORY_LIMIT} \
    --device-read-bps /dev/sda:${DEFAULT_IO_LIMIT} \
    -v $(pwd):/workspace:ro \
    -v ${KUBECONFIG%/*}:/root/.kube:ro \
    --network=host \
    ${ZAKENAK_IMAGE}:${ZAKENAK_VERSION} converge
```

### GPU-специфичная безопасность
```yaml
# Пример конфигурации Pod Security Context
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: gpu-container
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      readOnlyRootFilesystem: true
    resources:
      limits:
        nvidia.com/gpu: "${GPU_COUNT:-1}"
        memory: "${DEFAULT_GPU_MEMORY_LIMIT}"
        nvidia.com/gpu-memory: "${DEFAULT_GPU_MEMORY_LIMIT}"
      requests:
        nvidia.com/gpu: "1"
        memory: "4Gi"
    env:
    - name: NVIDIA_VISIBLE_DEVICES
      value: "all"
    - name: NVIDIA_DRIVER_CAPABILITIES
      value: "compute,utility"
    - name: CUDA_CACHE_DISABLE
      value: "1"
```

### Мониторинг безопасности GPU
```bash
# Мониторинг аномалий GPU
docker run --gpus all \
    -v /etc/prometheus:/etc/prometheus \
    ${ZAKENAK_IMAGE}:${ZAKENAK_VERSION} \
    nvidia-smi dmon -s pucvmet -f ${GPU_METRICS_LOG}

# Аудит GPU событий
docker run --gpus all \
    -v ${LOG_DIR}:${LOG_DIR} \
    -e AUDIT_LEVEL=${DEFAULT_AUDIT_LEVEL} \
    ${ZAKENAK_IMAGE}:${ZAKENAK_VERSION} audit
```

### Защита от криптомайнинга
1. Ограничение процессов и ресурсов:
```bash
docker run --gpus all \
    --pids-limit 50 \
    --cpu-shares 512 \
    --memory-swap 0 \
    --device-read-bps /dev/sda:1mb \
    --device-write-bps /dev/sda:1mb \
    ghcr.io/i8megabit/zakenak:1.0.0
```

2. Мониторинг подозрительной активности:
```bash
# Установка алертов на аномальное использование
docker run --gpus all \
    -v $(pwd)/monitoring:/etc/prometheus \
    -e ALERT_ON_HIGH_USAGE=true \
    -e GPU_USAGE_THRESHOLD=${DEFAULT_GPU_USAGE_THRESHOLD} \
    ${ZAKENAK_IMAGE}:${ZAKENAK_VERSION} monitor
```

### Сетевая изоляция
```bash
# Запуск с ограниченным сетевым доступом
docker run --gpus all \
    --network=none \
    --dns ${DEFAULT_DNS_SERVERS} \
    ${ZAKENAK_IMAGE}:${ZAKENAK_VERSION}

# Использование пользовательской сети с правилами
docker network create --driver ${DEFAULT_NETWORK_DRIVER} \
    --opt com.docker.network.bridge.name=${DEFAULT_NETWORK_NAME} \
    --opt com.docker.network.bridge.enable_icc=false \
    ${DEFAULT_NETWORK_NAME}

docker run --gpus all \
    --network=${DEFAULT_NETWORK_NAME} \
    --network-alias=zakenak \
    ${ZAKENAK_IMAGE}:${ZAKENAK_VERSION}

```

### Аудит и логирование
```bash
# Включение расширенного аудита
docker run --gpus all \
    -v ${LOG_DIR}:${LOG_DIR} \
    -e AUDIT_LEVEL=${DEFAULT_AUDIT_LEVEL} \
    -e AUDIT_LOG_PATH=${AUDIT_LOG_PATH} \
    -e LOG_FORMAT=json \
    ${ZAKENAK_IMAGE}:${ZAKENAK_VERSION}

# Мониторинг событий безопасности
docker run --gpus all \
    -v /var/log/zakenak:/var/log/zakenak \
    -e SECURITY_MONITORING=true \
    -e ALERT_ON_VIOLATION=true \
    ghcr.io/i8megabit/zakenak:1.0.0 monitor
```

### Дополнительные меры безопасности
1. Регулярное обновление образов:
```bash
# Проверка и обновление образа
docker pull ghcr.io/i8megabit/zakenak:1.0.0
docker image prune -f
```

2. Сканирование уязвимостей:
```bash
# Сканирование образа
docker scan ghcr.io/i8megabit/zakenak:1.0.0

# Проверка конфигурации на соответствие CIS
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy image ghcr.io/i8megabit/zakenak:1.0.0
```

3. Проверка целостности:
```bash
# Проверка подписи образа
docker trust inspect ghcr.io/i8megabit/zakenak:1.0.0

# Верификация компонентов
docker run --gpus all \
    -e VERIFY_COMPONENTS=true \
    ghcr.io/i8megabit/zakenak:1.0.0 verify
```

## Устранение неполадок

### Диагностика GPU
```bash
# Проверка статуса GPU
nvidia-smi

# Проверка NVIDIA Container Toolkit
docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu22.04 nvidia-smi

# Проверка GPU в кластере
kubectl get nodes -l nvidia.com/gpu=true
kubectl describe node -l nvidia.com/gpu=true | grep nvidia.com/gpu
```

```plain text
Copyright (c) 2025 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. 
See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT.
```