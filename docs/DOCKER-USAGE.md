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
git clone https://github.com/i8megabit/zakenak
cd zakenak
sudo ./scripts/setup/docker-setup.sh
```

Скрипт автоматически:
- Проверяет системные требования
- Устанавливает зависимости
- Настраивает NVIDIA Container Toolkit
- Проверяет корректность установки

### Проверка установки
```bash
# Базовая проверка Docker
docker info

# Проверка GPU поддержки
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi
```

## Использование образа

### Получение образа
```bash
# Рекомендуемый способ (фиксированная версия)
docker pull ghcr.io/i8megabit/zakenak:1.0.0

# Последняя версия (не рекомендуется для production)
docker pull ghcr.io/i8megabit/zakenak:latest
```

### Базовое использование

```bash
# Стандартный запуск
docker run --gpus all \
    -v $(pwd):/workspace \
    -v ~/.kube:/root/.kube \
    -v ~/.cache/zakenak:/root/.cache/zakenak \
    --network host \
    ghcr.io/i8megabit/zakenak:1.0.0 converge

# Запуск с дополнительными параметрами
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

### Лучшие практики
```bash
# Безопасный запуск
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

### Диагностика GPU
```bash
# Проверка GPU статуса
docker run --gpus all \
    ghcr.io/i8megabit/zakenak:1.0.0 \
    nvidia-smi -q

# Проверка конфигурации
docker run -v $(pwd):/workspace \
    ghcr.io/i8megabit/zakenak:1.0.0 \
    validate
```

```plain text
Copyright (c) 2025 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. 
See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT.
```

