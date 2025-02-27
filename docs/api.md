# API Reference

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
  - [API Reference](api.md) (текущий документ)
  - [Устранение неполадок](troubleshooting.md)
  - [GPU в WSL2](GPU-WSL.md)
  - [Использование Docker](DOCKER-USAGE.md)
  - [Настройка KUBECONFIG](KUBECONFIG.md)
  - [Мониторинг](MONITORING.md)
  - [Настройка сети](NETWORK-CONFIGURATION.md)
- [Примеры](../examples/README.md)

## Содержание
1. [CLI API](#cli-api)
2. [REST API](#rest-api)
3. [Конфигурационный API](#конфигурационный-api)
4. [Helm API](#helm-api)
5. [Интеграционный API](#интеграционный-api)

## CLI API

### Основные команды

#### `zakenak converge`
Выполняет конвергенцию состояния кластера с желаемым состоянием из конфигурации.

```bash
zakenak converge [--config <path>] [--debug] [--dry-run]
```

| Параметр | Описание | По умолчанию |
|----------|-----------|--------------|
| `--config` | Путь к конфигурационному файлу | `./zakenak.yaml` |
| `--debug` | Включение отладочного режима | `false` |
| `--dry-run` | Запуск без применения изменений | `false` |

#### `zakenak build`
Выполняет сборку образов с поддержкой GPU.

```bash
zakenak build [--config <path>] [--tag <tag>] [--push]
```

| Параметр | Описание | По умолчанию |
|----------|-----------|--------------|
| `--config` | Путь к конфигурационному файлу | `./zakenak.yaml` |
| `--tag` | Тег для образа | `latest` |
| `--push` | Отправить образ в registry | `false` |

#### `zakenak deploy`
Выполняет деплой в кластер Kubernetes.

```bash
zakenak deploy [--config <path>] [--namespace <namespace>] [--wait]
```

| Параметр | Описание | По умолчанию |
|----------|-----------|--------------|
| `--config` | Путь к конфигурационному файлу | `./zakenak.yaml` |
| `--namespace` | Namespace для деплоя | `prod` |
| `--wait` | Ожидание готовности ресурсов | `false` |

### Дополнительные команды

#### `zakenak init`
Инициализирует новый проект Zakenak.

```bash
zakenak init [--dir <directory>] [--template <template>]
```

| Параметр | Описание | По умолчанию |
|----------|-----------|--------------|
| `--dir` | Директория для инициализации | `.` |
| `--template` | Шаблон проекта | `basic` |

#### `zakenak status`
Показывает текущий статус проекта и кластера.

```bash
zakenak status [--config <path>] [--namespace <namespace>]
```

| Параметр | Описание | По умолчанию |
|----------|-----------|--------------|
| `--config` | Путь к конфигурационному файлу | `./zakenak.yaml` |
| `--namespace` | Namespace для проверки | `prod` |

#### `zakenak cleanup`
Очищает ресурсы, созданные Zakenak.

```bash
zakenak cleanup [--config <path>] [--namespace <namespace>] [--all]
```

| Параметр | Описание | По умолчанию |
|----------|-----------|--------------|
| `--config` | Путь к конфигурационному файлу | `./zakenak.yaml` |
| `--namespace` | Namespace для очистки | `prod` |
| `--all` | Очистить все ресурсы | `false` |

## REST API

Zakenak предоставляет REST API для интеграции с внешними системами.

### Аутентификация

API использует токены JWT для аутентификации.

```bash
# Получение токена
curl -X POST https://zakenak-api.example.com/auth \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "password"}'
```

### Endpoints

#### GET /api/v1/status
Возвращает текущий статус кластера.

```bash
curl -X GET https://zakenak-api.example.com/api/v1/status \
  -H "Authorization: Bearer <token>"
```

#### POST /api/v1/converge
Запускает процесс конвергенции.

```bash
curl -X POST https://zakenak-api.example.com/api/v1/converge \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"config": "path/to/config.yaml"}'
```

#### POST /api/v1/deploy
Запускает процесс деплоя.

```bash
curl -X POST https://zakenak-api.example.com/api/v1/deploy \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"config": "path/to/config.yaml", "namespace": "prod"}'
```

#### GET /api/v1/resources
Возвращает список ресурсов в кластере.

```bash
curl -X GET https://zakenak-api.example.com/api/v1/resources \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"namespace": "prod", "kind": "Deployment"}'
```

## Конфигурационный API

Zakenak использует YAML для конфигурации проектов.

### Основная структура

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

### Секции конфигурации

#### `project`
Имя проекта.

#### `environment`
Окружение (prod, dev, staging).

#### `registry`
Конфигурация container registry.

| Параметр | Описание | Обязательный |
|----------|-----------|--------------|
| `url` | URL registry | Да |
| `username` | Имя пользователя | Нет |
| `password` | Пароль | Нет |

#### `deploy`
Конфигурация деплоя.

| Параметр | Описание | Обязательный |
|----------|-----------|--------------|
| `namespace` | Namespace для деплоя | Да |
| `charts` | Список Helm чартов | Да |
| `values` | Список values файлов | Нет |

#### `build`
Конфигурация сборки.

| Параметр | Описание | Обязательный |
|----------|-----------|--------------|
| `context` | Контекст сборки | Да |
| `dockerfile` | Путь к Dockerfile | Да |
| `args` | Аргументы сборки | Нет |
| `gpu` | Конфигурация GPU | Нет |

## Helm API

Zakenak интегрируется с Helm для управления чартами.

### Структура чарта

```
helm-charts/ollama/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── pvc.yaml
└── charts/
    └── dependency-chart/
```

### Chart.yaml

```yaml
apiVersion: v2
name: ollama
version: 0.2.0
description: Helm chart for Ollama with GPU support
type: application
appVersion: "1.0.0"
dependencies:
  - name: common
    version: 1.0.0
    repository: https://charts.bitnami.com/bitnami
```

### values.yaml

```yaml
deployment:
  replicas: 1
  useGPU: true
  resources:
    limits:
      nvidia.com/gpu: 1
      memory: "8Gi"
      cpu: "2000m"
    requests:
      memory: "4Gi"
      cpu: "1000m"

service:
  type: ClusterIP
  port: 11434

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: ollama.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: ollama-tls
      hosts:
        - ollama.example.com

persistence:
  enabled: true
  size: 20Gi
  storageClass: standard
```

## Интеграционный API

> Для подробной информации о GitOps подходе и интеграциях см. [GitOps подход](GITOPS.md).

Zakenak предоставляет API для интеграции с внешними системами.

### Webhooks

#### Webhook для CI/CD

```bash
# Webhook для запуска конвергенции после push в Git
curl -X POST https://zakenak-api.example.com/webhooks/git \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: <secret>" \
  -d '{"repository": "myapp", "branch": "main", "commit": "abc123"}'
```

#### Webhook для мониторинга

```bash
# Webhook для оповещения о проблемах
curl -X POST https://zakenak-api.example.com/webhooks/alert \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: <secret>" \
  -d '{"severity": "critical", "message": "GPU memory usage exceeded threshold"}'
```

### Интеграция с внешними системами

#### Prometheus

Zakenak экспортирует метрики в формате Prometheus.

```bash
# Endpoint для метрик
curl -X GET https://zakenak-api.example.com/metrics
```

#### Grafana

Zakenak предоставляет готовые дашборды для Grafana.

```bash
# Импорт дашборда
curl -X POST https://grafana.example.com/api/dashboards/import \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"dashboard": {...}, "folderId": 0, "overwrite": true}'
```

```plain text
Copyright (c) 2025 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. 
See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT.
```