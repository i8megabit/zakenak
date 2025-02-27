# Примеры использования Zakenak

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
  - [Руководство по развертыванию](../docs/DEPLOYMENT.md)
  - [GitOps подход](../docs/GITOPS.md)
  - [API Reference](../docs/api.md)
  - [Устранение неполадок](../docs/troubleshooting.md)
  - [GPU в WSL2](../docs/GPU-WSL.md)
  - [Использование Docker](../docs/DOCKER-USAGE.md)
  - [Настройка KUBECONFIG](../docs/KUBECONFIG.md)
  - [Мониторинг](../docs/MONITORING.md)
  - [Настройка сети](../docs/NETWORK-CONFIGURATION.md)
- [Примеры](../examples/README.md) (текущий документ)

## Содержание
1. [Базовый пример](#базовый-пример)
2. [Пример с GPU](#пример-с-gpu)
3. [Пример с GitOps](#пример-с-gitops)
4. [Пример с мониторингом](#пример-с-мониторингом)

## Базовый пример

В этом примере показано базовое использование Zakenak для развертывания приложения в Kubernetes.

### Структура проекта
```
basic-example/
├── zakenak.yaml
├── values.yaml
└── Dockerfile
```

### zakenak.yaml
```yaml
project: basic-app
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
    - ./helm-charts/basic-app
  values:
    - values.yaml

build:
  context: .
  dockerfile: Dockerfile
  args:
    VERSION: v1.0.0
```

### values.yaml
```yaml
basic-app:
  replicas: 2
  image:
    repository: registry.local/basic-app
    tag: latest
  service:
    type: ClusterIP
    port: 8080
  ingress:
    enabled: true
    hosts:
      - host: app.example.com
        paths:
          - path: /
            pathType: Prefix
```

### Dockerfile
```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Использование
```bash
# Сборка образа
zakenak build

# Деплой в кластер
zakenak deploy

# Конвергенция состояния
zakenak converge
```

## Пример с GPU

В этом примере показано использование Zakenak для развертывания приложения с поддержкой GPU.

### Структура проекта
```
gpu-example/
├── zakenak.yaml
├── values.yaml
└── Dockerfile
```

### zakenak.yaml
```yaml
project: gpu-app
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
    - ./helm-charts/gpu-app
  values:
    - values.yaml

build:
  context: .
  dockerfile: Dockerfile
  args:
    CUDA_VERSION: 12.6.0
  gpu:
    enabled: true
    runtime: nvidia
    memory: "8Gi"
    devices: "all"
```

### values.yaml
```yaml
gpu-app:
  replicas: 1
  image:
    repository: registry.local/gpu-app
    tag: latest
  resources:
    limits:
      nvidia.com/gpu: 1
      memory: "8Gi"
      cpu: "2000m"
    requests:
      memory: "4Gi"
      cpu: "1000m"
  nodeSelector:
    nvidia.com/gpu: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
```

### Dockerfile
```dockerfile
FROM nvidia/cuda:12.6.0-base-ubuntu22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python3", "app.py"]
```

### Использование
```bash
# Сборка образа с GPU поддержкой
zakenak build --gpu

# Деплой в кластер
zakenak deploy

# Проверка GPU в контейнере
kubectl exec -it -n prod $(kubectl get pods -n prod -l app=gpu-app -o name) -- nvidia-smi
```

## Пример с GitOps

В этом примере показано использование Zakenak с GitOps подходом.

### Структура проекта
```
gitops-example/
├── zakenak.yaml
├── values.yaml
└── .github/
    └── workflows/
        └── deploy.yaml
```

### zakenak.yaml
```yaml
project: gitops-app
environment: prod

registry:
  url: ghcr.io
  username: ${GITHUB_USER}
  password: ${GITHUB_TOKEN}

deploy:
  namespace: prod
  charts:
    - ./helm-charts/cert-manager
    - ./helm-charts/local-ca
    - ./helm-charts/gitops-app
  values:
    - values.yaml

gitops:
  enabled: true
  repository: github.com/user/gitops-repo
  branch: main
  path: clusters/prod
  interval: 5m
```

### .github/workflows/deploy.yaml
```yaml
name: Deploy

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v1
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Build and Push
        run: |
          zakenak build --push
      
      - name: Update GitOps Repository
        run: |
          zakenak gitops sync
```

### Использование
```bash
# Локальная проверка
zakenak gitops preview

# Синхронизация с GitOps репозиторием
zakenak gitops sync

# Проверка статуса
zakenak gitops status
```

## Пример с мониторингом

В этом примере показано использование Zakenak с мониторингом.

### Структура проекта
```
monitoring-example/
├── zakenak.yaml
├── values.yaml
└── monitoring/
    ├── prometheus-values.yaml
    ├── grafana-values.yaml
    └── dashboards/
        └── gpu-dashboard.json
```

### zakenak.yaml
```yaml
project: monitored-app
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
    - ./helm-charts/monitored-app
    - ./helm-charts/prometheus
    - ./helm-charts/grafana
  values:
    - values.yaml
    - monitoring/prometheus-values.yaml
    - monitoring/grafana-values.yaml

monitoring:
  enabled: true
  prometheus:
    enabled: true
    retention: 15d
  grafana:
    enabled: true
    dashboards:
      - monitoring/dashboards/gpu-dashboard.json
  alerts:
    enabled: true
    receivers:
      - name: slack
        slack_configs:
          - channel: '#alerts'
            api_url: ${SLACK_WEBHOOK_URL}
```

### monitoring/prometheus-values.yaml
```yaml
prometheus:
  prometheusSpec:
    retention: 15d
    resources:
      limits:
        memory: 2Gi
        cpu: 1000m
      requests:
        memory: 1Gi
        cpu: 500m
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: standard
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
```

### Использование
```bash
# Деплой с мониторингом
zakenak deploy

# Проверка метрик
zakenak monitoring metrics

# Доступ к Grafana
zakenak monitoring dashboard
```

> Для более подробной информации о мониторинге см. [Мониторинг](../docs/MONITORING.md).

```plain text
Copyright (c) 2025 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. 
See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT.
```