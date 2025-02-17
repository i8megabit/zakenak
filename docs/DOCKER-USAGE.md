# Руководство по использованию Docker в Ƶakenak™®

```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

Should Harbour?	No.
```

## Подготовка окружения

### Требования
- Windows 11 Pro/Enterprise
- WSL2 с Ubuntu 22.04
- Docker Desktop с WSL2 бэкендом
- NVIDIA Container Toolkit
- CUDA Toolkit 12.8+
- Минимум 16GB RAM
- NVIDIA GPU (Compute Capability 7.0+)

### Настройка NVIDIA Container Toolkit
```bash
# Установка репозитория
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Установка toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

## Использование официального образа

### Получение образа
```bash
# Последняя версия
docker pull ghcr.io/i8megabit/zakenak:latest

# Конкретная версия (рекомендуется)
docker pull ghcr.io/i8megabit/zakenak:1.0.0

# Проверка GPU поддержки
docker run --rm --gpus all ghcr.io/i8megabit/zakenak:1.0.0 nvidia-smi
```

### Базовое использование

#### 1. Запуск с локальной конфигурацией
```bash
docker run --gpus all \
    -v $(pwd):/workspace \
    -v ~/.kube:/root/.kube \
    -v ~/.cache/zakenak:/root/.cache/zakenak \
    --network host \
    ghcr.io/i8megabit/zakenak:1.0.0 converge
```

#### 2. Запуск с указанием конфигурации
```bash
docker run --gpus all \
    -v $(pwd):/workspace \
    -v ~/.kube:/root/.kube \
    -e NVIDIA_VISIBLE_DEVICES=all \
    -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    ghcr.io/i8megabit/zakenak:1.0.0 \
    --config /workspace/zakenak.yaml \
    converge
```

## Конфигурация

### Структура zakenak.yaml
```yaml
version: "1.0"
project: myapp
environment: prod

# Настройки registry
registry:
  url: registry.local
  username: ${REGISTRY_USER}
  password: ${REGISTRY_PASS}
  insecure: false

# Настройки развертывания
deploy:
  namespace: prod
  charts:
    - name: cert-manager
      path: ./helm-charts/cert-manager
      values:
        - values.yaml
        - values-prod.yaml
    - name: local-ca
      path: ./helm-charts/local-ca
    - name: ollama
      path: ./helm-charts/ollama
      values:
        - values-gpu.yaml
    - name: open-webui
      path: ./helm-charts/open-webui

# Настройки сборки
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
```

## GPU оптимизация

### Настройка памяти GPU
```bash
docker run --gpus all \
    -e NVIDIA_VISIBLE_DEVICES=all \
    -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    -e GPU_MEMORY_FRACTION=0.8 \
    ghcr.io/i8megabit/zakenak:1.0.0 converge
```

### Multi-GPU конфигурация
```bash
# Использование конкретных GPU
docker run --gpus '"device=0,1"' \
    -v $(pwd):/workspace \
    ghcr.io/i8megabit/zakenak:1.0.0 converge

# Распределение нагрузки
docker run --gpus all \
    -e GPU_SPLIT_MODE="balanced" \
    -e GPU_MEMORY_FRACTION=0.7 \
    ghcr.io/i8megabit/zakenak:1.0.0 converge
```

## Примеры использования

### 1. Установка компонентов
```bash
# Установка cert-manager
docker run --gpus all \
    -v $(pwd):/workspace \
    -v ~/.kube:/root/.kube \
    ghcr.io/i8megabit/zakenak:1.0.0 \
    deploy --chart ./helm-charts/cert-manager

# Установка Ollama с GPU
docker run --gpus all \
    -v $(pwd):/workspace \
    -v ~/.kube:/root/.kube \
    ghcr.io/i8megabit/zakenak:1.0.0 \
    deploy --chart ./helm-charts/ollama \
    --values ./helm-charts/ollama/values-gpu.yaml
```

### 2. Мониторинг GPU
```bash
# Мониторинг использования GPU
docker run --gpus all \
    ghcr.io/i8megabit/zakenak:1.0.0 \
    nvidia-smi dmon -s pucvmet

# Проверка памяти GPU
docker run --gpus all \
    ghcr.io/i8megabit/zakenak:1.0.0 \
    nvidia-smi --query-gpu=memory.used,memory.total --format=csv
```

### 3. Отладка
```bash
# Включение отладочного режима
docker run --gpus all \
    -v $(pwd):/workspace \
    -e ZAKENAK_DEBUG=true \
    -e NVIDIA_DEBUG=1 \
    ghcr.io/i8megabit/zakenak:1.0.0 converge

# Проверка конфигурации
docker run --gpus all \
    -v $(pwd):/workspace \
    ghcr.io/i8megabit/zakenak:1.0.0 \
    validate --config /workspace/zakenak.yaml
```

## Переменные окружения

| Переменная | Описание | По умолчанию |
|------------|-----------|--------------|
| `KUBECONFIG` | Путь к kubeconfig | `~/.kube/config` |
| `ZAKENAK_DEBUG` | Включение отладки | `false` |
| `NVIDIA_VISIBLE_DEVICES` | GPU устройства | `all` |
| `NVIDIA_DRIVER_CAPABILITIES` | Возможности драйвера | `compute,utility` |
| `GPU_MEMORY_FRACTION` | Доля памяти GPU | `0.9` |
| `GPU_SPLIT_MODE` | Режим разделения GPU | `exclusive` |
| `REGISTRY_USER` | Пользователь registry | - |
| `REGISTRY_PASS` | Пароль registry | - |

## Монтирование томов

### Обязательные тома
- `/workspace`: Рабочая директория
- `~/.kube`: Конфигурация Kubernetes

### Опциональные тома
- `~/.cache/zakenak`: Кэш для ускорения работы
- `/var/run/docker.sock`: Доступ к Docker daemon
- `/etc/nvidia`: Конфигурация NVIDIA

## Безопасность

### Рекомендации
1. Использовать фиксированные версии образов
2. Применять принцип минимальных привилегий
3. Изолировать сетевой доступ
4. Проверять целостность образов
5. Регулярно обновлять компоненты

### Пример безопасного запуска
```bash
docker run --gpus all \
    --read-only \
    --security-opt=no-new-privileges \
    --cap-drop ALL \
    --cap-add SYS_ADMIN \
    -v $(pwd):/workspace:ro \
    -v ~/.kube:/root/.kube:ro \
    --network=host \
    ghcr.io/i8megabit/zakenak:1.0.0 converge
```

## Устранение неполадок

### GPU проблемы
1. Проверка доступности GPU:
```bash
docker run --gpus all nvidia/cuda:12.8.0-base nvidia-smi
```

2. Проверка драйверов:
```bash
docker run --gpus all \
    ghcr.io/i8megabit/zakenak:1.0.0 \
    nvidia-smi -q
```

3. Проверка CUDA:
```bash
docker run --gpus all \
    ghcr.io/i8megabit/zakenak:1.0.0 \
    nvidia-smi -L
```

### Общие проблемы
1. Проверка конфигурации:
```bash
docker run -v $(pwd):/workspace \
    ghcr.io/i8megabit/zakenak:1.0.0 \
    validate
```

2. Проверка прав доступа:
```bash
docker run -v $(pwd):/workspace \
    ghcr.io/i8megabit/zakenak:1.0.0 \
    check-permissions
```

3. Диагностика сети:
```bash
docker run --network host \
    ghcr.io/i8megabit/zakenak:1.0.0 \
    connectivity-test
```

```plain text
Copyright (c) 2025 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. 
See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT.

The name "Zakenak" and associated branding are trademarks of @eberil and may not be used 
without express written permission.
```