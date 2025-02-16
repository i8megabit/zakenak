# Ƶakenak™® GitOps Repository

Copyright (c) 2024 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the
MIT License. See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

The name "Zakenak" and associated branding are trademarks of @eberil
and may not be used without express written permission.

## Версия
1.3.1

## Описание
Монорепозиторий для управления Kubernetes-инфраструктурой и GPU-ускоренными AI сервисами в среде WSL2.

## Компоненты системы

### Core Services
- cert-manager: Управление TLS сертификатами
- local-ca: Локальный центр сертификации
- sidecar-injector: Инжекция TLS прокси

### AI Services
- ollama: LLM сервер с GPU-акселерацией
- open-webui: Веб-интерфейс для Ollama

### Infrastructure
- NVIDIA device plugin для WSL2
- CoreDNS с поддержкой .prod.local зоны
- Ingress контроллер с TLS

## Системные требования

### Hardware
- NVIDIA GPU с поддержкой CUDA (Compute Capability 7.0+)
- Минимум 16GB RAM
- SSD хранилище

### Software
- Windows 11 с WSL2 (Ubuntu 22.04 LTS)
- NVIDIA Driver 535.104.05+
- CUDA Toolkit 12.8
- Docker с NVIDIA Container Runtime
- Kubernetes 1.25+

## Быстрый старт

### 1. Подготовка WSL2
```bash
./tools/reset-wsl/Reset-WSL.ps1
```

### 2. Установка кластера
```bash
./tools/k8s-kind-setup/deploy-all.sh
```

### 3. Проверка установки
```bash
# Проверка DNS
kubectl run -i --rm --restart=Never busybox --image=busybox:1.28 -- nslookup ollama.prod.local
kubectl run -i --rm --restart=Never busybox --image=busybox:1.28 -- nslookup webui.prod.local

# Проверка GPU
kubectl exec -it -n prod deployment/ollama -- nvidia-smi
```

## Структура репозитория
```
.
├── helm-charts/          # Helm чарты компонентов
├── tools/               # Инструменты развертывания
│   ├── connectivity-check/
│   ├── helm-deployer/
│   ├── k8s-kind-setup/
│   ├── reset-wsl/
│   └── zakenak/
└── docs/               # Документация
```

## Документация
- [Архитектура](docs/ARCHITECTURE.md)
- [Развертывание](docs/DEPLOYMENT.md)
- [GPU настройка](docs/GPU-SETUP.md)
- [Мониторинг](docs/MONITORING.md)
- [Безопасность](docs/SECURITY.md)

## Безопасность
- TLS для всех сервисов
- Изоляция подов
- Контроль доступа к GPU
- Аудит операций
- Network Policies

## Лицензирование
Проект распространяется под модифицированной MIT лицензией с защитой торговой марки. Использование названия "Zakenak" требует письменного разрешения владельца.

## Поддержка
- Email: security@i8megabit.com
- GitHub Issues: [Создать issue](https://github.com/i8meg/zakenak/issues)
