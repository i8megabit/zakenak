# Zakenak
```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

Should Harbour?	No.
```

[![Go Report Card](https://goreportcard.com/badge/github.com/i8megabit/zakenak)](https://goreportcard.com/report/github.com/i8megabit/zakenak)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/i8megabit/zakenak)][releases]

## [Zakenak](https://dic.academic.ru/dic.nsf/dic_synonims/390396/%D1%87%D0%B0%D0%BA%D0%B0%D0%BD%D0%B0%D0%BAчаканак "др.-чув. чӑканӑк — бухта, залив")

Zakenak — профессиональный инструмент GitOps для эффективной оркестрации Kubernetes-кластеров с поддержкой GPU через Helm.


### Ключевые преимущества
- 🚀 **Автономность**: Единый бинарный файл без внешних зависимостей
- 🔄 **GitOps**: Встроенная поддержка GitOps и автоматической конвергенции
- 🐳 **Интеграция**: Нативная работа с container registry
- 🖥️ **Совместимость**: Полная поддержка WSL2 и NVIDIA GPU
- 📝 **Простота**: Интуитивная но мощная система шаблонизации

## Начало работы

## Требования

- Docker Desktop с включенным Kubernetes
- kubectl
- Helm 3.0+
- NVIDIA GPU (опционально)
- NVIDIA Container Toolkit (для GPU)

## Быстрый старт

1. Установите Docker Desktop и включите Kubernetes в настройках
2. Проверьте готовность кластера:
   ```bash
   zakenak cluster verify
   ```
3. Установите компоненты:
   ```bash
   zakenak deploy
   ```

## Возможности

- Автоматическое развертывание в Docker Desktop Kubernetes
- Интеграция с NVIDIA GPU
- Управление сертификатами через cert-manager
- Локальный центр сертификации
- Web интерфейс для взаимодействия с LLM

## Документация

- [Развертывание](docs/DEPLOYMENT.md)
- [Настройка GPU](docs/GPU-SETUP.md)
- [Архитектура](docs/ARCHITECTURE.md)
- [Безопасность](docs/SECURITY.md)
## Использование Docker образа

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

### Использование с GPU
```bash
docker run --gpus all \
	-v $(pwd):/workspace \
	-v ~/.kube:/root/.kube \
	-e NVIDIA_VISIBLE_DEVICES=all \
	-e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
	ghcr.io/i8megabit/zakenak:latest converge
```

### Монтирование томов
#### Обязательные тома
- `/workspace`: Рабочая директория с конфигурацией
- `~/.kube`: Конфигурация Kubernetes

#### Опциональные тома
- `/root/.cache`: Кэш для ускорения работы
- `/var/run/docker.sock`: Для работы с локальным Docker

### Безопасность Docker контейнера
```bash
# Пример безопасного запуска
docker run --read-only \
	--security-opt=no-new-privileges \
	-v $(pwd):/workspace:ro \
	-v ~/.kube:/root/.kube:ro \
	--network=host \
	ghcr.io/i8megabit/zakenak:1.0.0 converge
```

## Базовая конфигурация
```bash
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

## Основные команды
```bash
# Конвергенция состояния
zakenak converge

# Сборка образов
zakenak build

# Деплой в кластер
zakenak deploy
```

## Переменные окружения
| Переменная | Описание | По умолчанию |
|------------|-----------|--------------|
| `KUBECONFIG` | Путь к kubeconfig | `~/.kube/config` |
| `ZAKENAK_DEBUG` | Включение отладки | `false` |
| `NVIDIA_VISIBLE_DEVICES` | GPU устройства | `all` |
| `REGISTRY_USER` | Пользователь registry | - |
| `REGISTRY_PASS` | Пароль registry | - |

## Архитектура
```mermaid
graph TD
    A[Git Repository] --> B[Ƶakanak]
    B --> C[Container Registry]
    B --> D[Kubernetes Cluster]
    B --> E[State Manager]
```

## Компоненты
- 💫 **State Manager**: Управление состоянием кластера
- 🔧 **Build System**: Сборка с поддержкой GPU
- 🎯 **Deploy Engine**: Умный деплой в Kubernetes
- 🔄 **GitOps Controller**: Синхронизация с Git
- 🎮 **CLI Interface**: Удобное управление

## Безопасность
- 🔒 Защита интеллектуальной собственности
- 🛡️ Встроенная поддержка RBAC
- 🔐 Безопасное хранение креденшелов
- ✅ Валидация конфигураций

## Лицензирование
Zakenak распространяется под MIT лицензией.

## Поддержка
- 📚 [Документация](docs/)
- 💡 [Примеры](examples/)
- 🔧 [Устранение неполадок](docs/troubleshooting.md)
- 📖 [API Reference](docs/api.md)

## Авторы
- [@eberil](https://github.com/eberil) - Основной разработчик

## Благодарности
- Команде Werf за вдохновение
- Сообществу Kubernetes
- Всем контрибьюторам

[releases]: https://github.com/i8megabit/zakenak/releases

```plain text
Copyright (c) 2025 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. 
See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT.
```