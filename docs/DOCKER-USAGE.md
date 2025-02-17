# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# 
# This file is part of Ƶakenak™® project.
# https://github.com/i8megabit/zakenak
#
# This program is free software and is released under the terms of the MIT License.
# See LICENSE.md file in the project root for full license information.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#
# TRADEMARK NOTICE:
# Ƶakenak™® and the Ƶakenak logo are registered trademarks of Mikhail Eberil.
# All rights reserved. The Ƶakenak trademark and brand may not be used in any way 
# without express written permission from the trademark owner.


# Запуск Ƶakenak™® в Docker

```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

Should Harbour?	No.
```
## Использование официального образа

### Получение образа
```bash
# Получение последней версии
docker pull ghcr.io/i8megabit/zakenak:latest

# Получение конкретной версии
docker pull ghcr.io/i8megabit/zakenak:1.0.0
```

### Базовое использование
```bash
# Запуск с конфигурацией из текущей директории
docker run -v $(pwd):/workspace \
	-v ~/.kube:/root/.kube \
	ghcr.io/i8megabit/zakenak:latest converge

# Запуск с указанием конфигурации
docker run -v $(pwd):/workspace \
	-v ~/.kube:/root/.kube \
	ghcr.io/i8megabit/zakenak:latest \
	--config /workspace/zakenak.yaml \
	converge
```

### Пример конфигурации
```yaml
project: myapp
environment: prod

registry:
  url: registry.local
  username: ${REGISTRY_USER}
  password: ${REGISTRY_PASS}

deploy:
  namespace: prod
  charts:
    - ./helm-charts/cert-manager
    - ./helm-charts/local-ca
    - ./helm-charts/ollama
    - ./helm-charts/open-webui
	values:
    - values.yaml
    - values-prod.yaml

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
```

### Использование GPU
Для работы с GPU необходимо использовать NVIDIA Container Runtime:

```bash
docker run --gpus all \
	-v $(pwd):/workspace \
	-v ~/.kube:/root/.kube \
	-e NVIDIA_VISIBLE_DEVICES=all \
	-e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
	ghcr.io/i8megabit/zakenak:latest converge
```

## Примеры использования

### 1. Установка cert-manager
```bash
docker run -v $(pwd):/workspace \
	-v ~/.kube:/root/.kube \
	ghcr.io/i8megabit/zakenak:latest \
	deploy --chart ./helm-charts/cert-manager
```

### 2. Установка Ollama с GPU
```bash
docker run --gpus all \
	-v $(pwd):/workspace \
	-v ~/.kube:/root/.kube \
	ghcr.io/i8megabit/zakenak:latest \
	deploy --chart ./helm-charts/ollama \
	--values ./helm-charts/ollama/values-gpu.yaml
```

### 3. Полная конвергенция состояния
```bash
docker run -v $(pwd):/workspace \
	-v ~/.kube:/root/.kube \
	ghcr.io/i8megabit/zakenak:latest converge
```

## Переменные окружения

| Переменная | Описание | По умолчанию |
|------------|-----------|--------------|
| `KUBECONFIG` | Путь к kubeconfig | `~/.kube/config` |
| `ZAKENAK_DEBUG` | Включение отладки | `false` |
| `NVIDIA_VISIBLE_DEVICES` | GPU устройства | `all` |
| `REGISTRY_USER` | Пользователь registry | - |
| `REGISTRY_PASS` | Пароль registry | - |

## Монтирование томов

### Обязательные тома
- `/workspace`: Рабочая директория с конфигурацией
- `~/.kube`: Конфигурация Kubernetes

### Опциональные тома
- `/root/.cache`: Кэш для ускорения работы
- `/var/run/docker.sock`: Для работы с локальным Docker

## Безопасность

### Рекомендации
1. Используйте конкретные версии образов вместо latest
2. Не передавайте чувствительные данные через переменные окружения
3. Используйте RBAC для ограничения доступа
4. Проверяйте целостность образов

### Пример безопасного запуска
```bash
docker run --read-only \
	--security-opt=no-new-privileges \
	-v $(pwd):/workspace:ro \
	-v ~/.kube:/root/.kube:ro \
	--network=host \
	ghcr.io/i8megabit/zakenak:1.0.0 converge
```

## Устранение неполадок

### Проверка GPU
```bash
docker run --gpus all \
	ghcr.io/i8megabit/zakenak:latest \
	nvidia-smi
```

### Проверка конфигурации
```bash
docker run -v $(pwd):/workspace \
	ghcr.io/i8megabit/zakenak:latest \
	--config /workspace/zakenak.yaml \
	validate
```

### Логи и отладка
```bash
docker run -v $(pwd):/workspace \
	-e ZAKENAK_DEBUG=true \
	ghcr.io/i8megabit/zakenak:latest converge
```