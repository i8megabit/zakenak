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

## Подготовка окружения

### Требования
- Windows 11 Pro/Enterprise
- WSL2 с Ubuntu 22.04
- Docker Desktop с WSL2 бэкендом
- NVIDIA Container Toolkit
- CUDA Toolkit 12.8+
- Минимум 16GB RAM
- NVIDIA GPU (Compute Capability 7.0+)

### Автоматическая установка
Для автоматической установки и настройки Docker и NVIDIA Container Toolkit используйте скрипт `docker-setup.sh`:

```bash
# Клонирование репозитория
git clone https://github.com/i8megabit/zakenak
cd zakenak

# Запуск скрипта установки
sudo ./scripts/setup/docker-setup.sh
```

Скрипт выполняет следующие действия:
- Проверяет системные требования (RAM, GPU)
- Определяет окружение (WSL2/native Linux)
- Устанавливает необходимые зависимости
- Настраивает NVIDIA Container Toolkit
- Проверяет корректность установки

#### Особенности работы скрипта
- В WSL2 пропускает установку Docker (должен быть установлен через Docker Desktop)
- В native Linux устанавливает Docker и добавляет пользователя в группу docker
- Автоматически настраивает NVIDIA Container Runtime
- Имеет встроенную систему повторных попыток при сбоях
- Предоставляет подробный вывод о процессе установки

#### Проверка установки
После завершения работы скрипта, проверьте установку:
```bash
# Проверка Docker
docker info

# Проверка NVIDIA Container Toolkit
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi
```

### Настройка NVIDIA Container Toolkit вручную
Если вы предпочитаете ручную установку, выполните следующие шаги:

```bash
# Установка необходимых пакетов
sudo apt-get update
sudo apt-get install -y wget curl

# Настройка keyring и репозитория
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Установка toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Проверка установки
sudo docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi
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

```plain text
Copyright (c)  2025 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

The name "Zakenak" and associated branding are trademarks of @eberil and may not be used without express written permission.
```