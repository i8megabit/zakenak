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


# Структура проекта Ƶakenak™®

```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

Should Harbour?	No.
```
## Общая структура репозитория

```
gitops/
├── cmd/                    # Исполняемые файлы
│   └── gitops/            # Основной бинарный файл
├── docs/                   # Документация
│   ├── ARCHITECTURE.md    # Архитектура системы
│   ├── DEPLOYMENT.md      # Инструкции по развертыванию
│   ├── GPU-SETUP.md       # Настройка GPU
│   ├── MONITORING.md      # Мониторинг системы
│   └── SECURITY.md        # Безопасность
├── helm-charts/           # Helm чарты
│   ├── cert-manager/      # Управление сертификатами
│   ├── local-ca/          # Локальный центр сертификации
│   ├── ollama/            # LLM сервер
│   ├── open-webui/        # Веб-интерфейс
│   └── sidecar-injector/  # Инжектор TLS сайдкаров
├── scripts/               # Скрипты автоматизации
├── tools/                 # Вспомогательные инструменты
│   ├── connectivity-check/# Проверка связности
│   ├── helm-deployer/     # Деплой Helm чартов
│   ├── k8s-kind-setup/    # Настройка Kind кластера
│   ├── reset-wsl/         # Сброс WSL
│   └── zakenak/           # Основной инструмент
└── manifests/             # Kubernetes манифесты
```

## Компоненты системы

### Core Services

1. **cert-manager**
   - Управление TLS сертификатами
   - Интеграция с локальным CA
   - Автоматическое обновление

2. **local-ca**
   - Генерация корневых сертификатов
   - Управление цепочками доверия
   - Выпуск сертификатов

3. **sidecar-injector**
   - Инжекция TLS прокси
   - Терминация TLS
   - Мониторинг состояния

### AI Services

1. **ollama**
   - LLM сервер с GPU
   - Управление моделями
   - Оптимизация GPU
   - Конфигурация:
	 - `deployment.yaml`
	 - `service.yaml`
	 - `ingress.yaml`
	 - `pvc.yaml`

2. **open-webui**
   - Веб-интерфейс
   - Интеграция с Ollama
   - Управление контекстом
   - Конфигурация: