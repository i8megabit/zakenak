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

```bash
zakenak/
├── cmd/                    # Исполняемые файлы
│   └── zakenak/           # Основной бинарный файл
│       ├── cluster.go     # Управление кластером
│       └── main.go        # Точка входа приложения
├── pkg/                    # Основные пакеты
│   ├── banner/            # ASCII баннеры и брендинг
│   ├── build/             # Сборка приложения
│   ├── config/            # Конфигурация
│   ├── converge/          # Согласование состояний
│   ├── helm/              # Helm интеграция
│   ├── kind/              # Kind кластер
│   └── state/             # Управление состоянием
├── docs/                   # Документация
│   ├── ARCHITECTURE.md    # Архитектура системы
│   ├── DEPLOYMENT.md      # Инструкции по развертыванию
│   ├── DOCKER-USAGE.md    # Использование Docker
│   ├── GITOPS.md          # GitOps практики
│   ├── GPU-SETUP.md       # Настройка GPU
│   ├── KUBECONFIG.md      # Настройка Kubernetes
│   ├── MONITORING.md      # Мониторинг системы
│   ├── SECURITY.md        # Безопасность
│   └── STRUCTURE.md       # Структура проекта
├── helm-charts/           # Helm чарты
│   ├── cert-manager/      # Управление сертификатами
│   │   ├── templates/     # Шаблоны манифестов
│   │   ├── values.yaml    # Значения по умолчанию
│   │   └── values-prod.yaml # Продакшн значения
│   ├── local-ca/          # Локальный центр сертификации
│   │   ├── templates/     # Шаблоны манифестов
│   │   └── values.yaml    # Конфигурация CA
│   ├── ollama/            # LLM сервер
│   │   ├── templates/     # Шаблоны манифестов
│   │   ├── values.yaml    # Базовая конфигурация
│   │   ├── values-gpu.yaml # GPU конфигурация
│   │   └── nvidia-device-plugin.yaml # NVIDIA плагин
│   ├── open-webui/        # Веб-интерфейс
│   │   ├── templates/     # Шаблоны манифестов
│   │   └── values.yaml    # Конфигурация UI
│   └── sidecar-injector/  # Инжектор TLS сайдкаров
│       ├── templates/     # Шаблоны манифестов
│       └── values.yaml    # Конфигурация инжектора
├── scripts/               # Скрипты автоматизации
│   ├── setup/            # Скрипты установки
│   │   ├── install-cuda.sh    # Установка CUDA
│   │   ├── setup-docker.sh    # Настройка Docker
│   │   └── setup-wsl.sh       # Настройка WSL2
│   ├── backup/           # Скрипты резервного копирования
│   │   ├── backup-etcd.sh     # Бэкап etcd
│   │   └── backup-certs.sh    # Бэкап сертификатов
│   └── monitoring/      # Скрипты мониторинга
│       ├── gpu-metrics.sh     # Сбор метрик GPU
│       └── health-check.sh    # Проверка здоровья
├── tools/                # Вспомогательные инструменты
│   ├── connectivity-check/ # Проверка связности
│   │   └── main.go         # Логика проверки
│   ├── helm-deployer/    # Деплой Helm чартов
│   │   └── main.go         # Логика деплоя
│   ├── k8s-kind-setup/   # Настройка Kind кластера
│   │   └── main.go         # Логика настройки
│   ├── reset-wsl/        # Сброс WSL
│   │   └── main.go         # Логика сброса
│   └── zakenak/          # Основной инструмент
│       ├── main.go         # Точка входа
│       └── scripts/        # Вспомогательные скрипты
└── manifests/            # Kubernetes манифесты
    ├── namespaces/       # Определения namespace
    ├── rbac/            # RBAC политики
    └── network-policies/ # Сетевые политики
```

## Компоненты системы

### Core Services

#### 1. cert-manager
- Управление TLS сертификатами
- Интеграция с локальным CA
- Автоматическое обновление
- Конфигурация:
  - `deployment.yaml`
  - `service.yaml`
  - `clusterissuer.yaml`

#### 2. local-ca
- Генерация корневых сертификатов
- Управление цепочками доверия
- Выпуск сертификатов
- Конфигурация:
  - `ca.yaml`
  - `issuer.yaml`
  - `secrets.yaml`

#### 3. sidecar-injector
- Инжекция TLS прокси
- Терминация TLS
- Мониторинг состояния
- Конфигурация:
  - `deployment.yaml`
  - `service.yaml`
  - `mutatingwebhook.yaml`

### AI Services

#### 1. ollama
- LLM сервер с GPU-акселерацией
- Управление моделями
- Оптимизация GPU
- Конфигурация:
  - `deployment.yaml`
  - `service.yaml`
  - `ingress.yaml`
  - `pvc.yaml`
  - `nvidia-config.yaml`

#### 2. open-webui
- Веб-интерфейс
- Интеграция с Ollama
- Управление контекстом
- Конфигурация:
  - `deployment.yaml`
  - `service.yaml`
  - `ingress.yaml`
  - `configmap.yaml`

### Infrastructure

#### 1. NVIDIA Integration
- Device Plugin
- Runtime Class
- Мониторинг ресурсов
- Конфигурация:
  - `nvidia-device-plugin.yaml`
  - `runtime-class.yaml`
  - `gpu-metrics.yaml`

#### 2. Networking
- Ingress Controller
- CoreDNS конфигурация
- Network Policies
- Конфигурация:
  - `ingress-controller.yaml`
  - `coredns-config.yaml`
  - `network-policies.yaml`

## Структура документации

### Основные документы
1. `ARCHITECTURE.md` - Архитектура системы
2. `DEPLOYMENT.md` - Инструкции по развертыванию
3. `DOCKER-USAGE.md` - Использование Docker
4. `GITOPS.md` - GitOps практики
5. `GPU-SETUP.md` - Настройка GPU
6. `KUBECONFIG.md` - Настройка Kubernetes
7. `MONITORING.md` - Мониторинг системы
8. `SECURITY.md` - Безопасность
9. `STRUCTURE.md` - Структура проекта

### Дополнительная документация
- `README.md` в каждой директории
- Комментарии в коде
- Примеры конфигурации
- Руководства по устранению неполадок

## Правила организации кода

### 1. Структура пакетов
- Логическое разделение по функциональности
- Минимальная связность между пакетами
- Четкие интерфейсы
- Документированные API

### 2. Именование
- Понятные и описательные имена
- Консистентный стиль
- Соответствие Go conventions
- Логическая группировка

### 3. Документация
- Godoc для всех публичных API
- README.md в каждой директории
- Примеры использования
- Комментарии к сложной логике

### 4. Тестирование
- Unit тесты
- Integration тесты
- E2E тесты
- Benchmarks

## Управление зависимостями

### 1. Go модули
- `go.mod` в корне проекта
- Фиксированные версии
- Регулярные обновления
- Аудит безопасности

### 2. Helm зависимости
- `Chart.yaml` в каждом чарте
- Версионирование зависимостей
- Локальные оверрайды
- Документированные требования

### 3. Docker образы
- Базовые образы с тегами
- Multi-stage builds
- Оптимизация слоев
- Сканирование уязвимостей

## Рабочий процесс

### 1. Разработка
- Feature branches
- Code review
- CI/CD пайплайны
- Автоматическое тестирование

### 2. Релизы
- Семантическое версионирование
- Changelog
- Release notes
- Автоматическая сборка

### 3. Деплой
- GitOps подход
- Автоматическая синхронизация
- Rollback механизмы
- Мониторинг состояния

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