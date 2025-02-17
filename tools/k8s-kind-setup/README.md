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


# Kubernetes Kind Setup для Ƶakenak™®

```ascii
     ______     _                      _    
    |___  /    | |                    | |   
       / / __ _| |  _ _   ___     ___ | |  _
      / / / _` | |/ / _`||  _ \ / _` || |/ /
     / /_| (_| |  < by_Eberil| | (_| ||   < 
    /_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\
  
    Should Harbour?	No.

## Версия
1.3.1

## Описание
Инструменты для настройки локального Kubernetes кластера с использованием Kind, оптимизированного для работы с GPU в среде WSL2.

## Особенности
- 🚀 Автоматическая настройка Kind кластера
- 🎮 Полная поддержка NVIDIA GPU в WSL2
- 🔒 Интеграция с локальным центром сертификации
- 🌐 Настройка DNS для .prod.local зоны
- 📊 Мониторинг GPU ресурсов

## Системные требования

### Hardware
- NVIDIA GPU с поддержкой CUDA (Compute Capability 7.0+)
- Минимум 16GB RAM
- SSD хранилище
- PCIe x16 слот

### Software
- Windows 11 с WSL2 (Ubuntu 22.04 LTS)
- NVIDIA Driver 535.104.05+
- CUDA Toolkit 12.8
- Docker с NVIDIA Container Runtime
- Kubernetes 1.25+
- Kind 0.20.0+

## Структура
```
.
├── manifests/                # Манифесты Kubernetes
│   ├── coredns/              # Конфигурация DNS
│   │   ├── custom-config.yaml
│   │   └── patch.yaml
│   └── nvidia/               # Конфигурация GPU
│       └── device-plugin.yaml
├── scripts/                  # Вспомогательные скрипты
│   ├── setup-gpu.sh         # Настройка GPU
│   └── setup-dns.sh         # Настройка DNS
├── env.sh                    # Переменные окружения
├── deploy-all.sh            # Полное развертывание
├── manage-charts.sh         # Управление чартами
└── README.md
```

## GPU Поддержка

### Настройка NVIDIA
```bash
# Проверка GPU в WSL2
nvidia-smi

# Настройка GPU для Kind
./scripts/setup-gpu.sh

# Проверка GPU в кластере
kubectl describe node | grep nvidia.com/gpu
```

### Параметры GPU
```yaml
# kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraMounts:
  - hostPath: /usr/lib/wsl/lib
	containerPath: /usr/lib/wsl/lib
  - hostPath: /usr/local/cuda-12.8
	containerPath: /usr/local/cuda-12.8
```

## Использование

### Полное развертывание
```bash
# Развертывание с GPU поддержкой
./deploy-all.sh --with-gpu

# Базовое развертывание
./deploy-all.sh
```

### Управление чартами
```bash
# Установка Ollama с GPU
./manage-charts.sh install ollama -n prod --set gpu.enabled=true

# Обновление конфигурации
./manage-charts.sh upgrade ollama -n prod --values values-gpu.yaml

# Просмотр статуса
./manage-charts.sh list
```

### Проверка DNS
```bash
# Проверка резолвинга
kubectl run -i --rm --restart=Never busybox --image=busybox:1.28 -- \
  nslookup ollama.prod.local

# Проверка GPU сервисов
kubectl run -i --rm --restart=Never busybox --image=busybox:1.28 -- \
  nslookup webui.prod.local
```

## Мониторинг

### GPU метрики
```bash
# Мониторинг GPU
watch -n 1 nvidia-smi

# Проверка в кластере
kubectl exec -it -n prod deployment/ollama -- nvidia-smi
```

### Логи
```bash
# Логи GPU плагина
kubectl logs -n kube-system -l k8s-app=nvidia-device-plugin-daemonset

# Логи DNS
kubectl logs -n kube-system -l k8s-app=kube-dns
```

## Безопасность
- TLS для всех сервисов
- Изоляция GPU ресурсов
- Network Policies
- RBAC для GPU доступа
- Аудит операций

## Устранение неполадок

### GPU проблемы
1. Проверьте драйверы NVIDIA:
```bash
nvidia-smi
nvidia-container-cli info
```

2. Проверьте монтирование в Kind:
```bash
docker exec -it kind-control-plane ls /usr/lib/wsl/lib
```

### DNS проблемы
1. Проверьте конфигурацию CoreDNS:
```bash
kubectl get configmap -n kube-system coredns -o yaml
```

2. Проверьте логи CoreDNS:
```bash
kubectl logs -n kube-system -l k8s-app=kube-dns
```

## Поддержка
- Email: i8megabit@gmail.com
- GitHub Issues: [Создать issue](https://github.com/i8megabit/zakenak/issues)
- Документация: [Руководство пользователя](../../docs/)

[def]: https://github.com/i8megabit/zakenak/releases