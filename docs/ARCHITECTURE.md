
# Архитектура Zakenak

Version: 1.0.0

```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

Should Harbour?	No.
```

## Общий обзор

Zakenak представляет собой современную платформу для работы с GPU-ускоренными LLM моделями, построенную на основе микросервисной архитектуры с использованием Kubernetes в качестве оркестратора. Система спроектирована с учетом требований безопасности, масштабируемости и производительности.

## Структура репозитория

```bash
zakenak/
├── cmd/zakenak/      # Точки входа приложения
├── pkg/              # Основные пакеты
└── helm-charts/      # Helm чарты компонентов
```

## Компоненты системы

### 1. Core Services

#### Cert Manager
- Управление жизненным циклом TLS сертификатов
- Автоматическое обновление и ротация
- Интеграция с внешними CA
- Мониторинг срока действия сертификатов
- Автоматическое восстановление при сбоях

#### Local CA
- Генерация и управление корневым сертификатом
- Выпуск сертификатов для внутренних сервисов
- Управление цепочками доверия
- Ротация ключей по расписанию
- Аудит операций с сертификатами

#### Sidecar Injector
- Автоматическая инжекция TLS прокси
- Терминация TLS соединений
- Управление сертификатами на уровне пода
- Мониторинг состояния прокси
- Автоматическое обновление конфигурации

### 2. AI Services

#### Ollama
- Запуск LLM моделей с GPU-акселерацией
- Оптимизированное управление GPU ресурсами
- Динамическая настройка параметров модели
- Мониторинг производительности
- Автоматическое восстановление при сбоях

#### Open WebUI
- Веб-интерфейс для взаимодействия с LLM
- Управление контекстом и историей
- Кастомизация промптов
- Мониторинг активности пользователей
- Интеграция с системой аутентификации

### 3. Infrastructure Services

#### NVIDIA Integration
- Device Plugin для GPU с поддержкой MIG
- Runtime Class для контейнеров
- Мониторинг ресурсов GPU
- Автоматическая настройка драйверов
- Оптимизация производительности

#### Networking
- Ingress Controller с поддержкой TLS
- CoreDNS с кастомной конфигурацией
- Network Policies для изоляции
- Мониторинг сетевой активности
- DDoS защита

## Безопасность

### Identity и Access Management
- RBAC для всех компонентов
- Service Accounts с минимальными привилегиями
- Интеграция с внешними IdP
- Аудит доступа
- Регулярный пересмотр прав

### TLS Flow
1. Local CA генерирует корневой сертификат
2. Cert Manager запрашивает сертификаты для сервисов
3. Sidecar Injector внедряет TLS прокси
4. Ingress терминирует внешний TLS
5. Мониторинг и аудит TLS соединений

### GPU Security
1. Node Labels для GPU ресурсов
2. Resource Quotas и LimitRanges
3. Pod Security Policies
4. NVIDIA Runtime изоляция
5. Мониторинг использования GPU

### Network Security
1. Network Policies для всех namespaces
2. Egress фильтрация
3. Pod-to-pod encryption
4. Service Mesh (опционально)
5. WAF для внешних endpoint'ов

## Масштабирование

### Вертикальное
- Динамическое управление ресурсами
- GPU Memory Optimization
- Batch Size адаптация
- Автоматическая настройка параметров
- Профилирование производительности

### Горизонтальное
- Multi-GPU поддержка
- Pod распределение
- Load Balancing
- Auto-scaling на основе метрик
- Географическое распределение

## Мониторинг и Observability

### Метрики
- GPU Utilization и Memory Usage
- Temperature и Power Consumption
- Latency и Throughput
- Error Rates
- Resource Usage

### Логирование
- Централизованный сбор логов
- Структурированный формат (JSON)
- Retention Policies
- Log Aggregation
- Real-time Analysis

### Алертинг
- Предупреждения о состоянии GPU
- Мониторинг производительности
- Безопасность и аномалии
- Интеграция с системами оповещения
- Автоматическое реагирование

## Развертывание

### Процесс
1. Инициализация кластера
2. Установка Core Services
3. Настройка GPU support
4. Развертывание AI сервисов
5. Валидация развертывания

### Конфигурация
- Helm Values
- Environment Variables
- ConfigMaps
- Secrets
- Custom Resources

## Требования к окружению

### Hardware
- NVIDIA GPU (Compute Capability 7.0+)
- 16GB RAM минимум
- NVMe SSD storage
- 10Gbps сеть (рекомендуется)
- Redundant Power Supply

### Software
- WSL2 с Ubuntu 22.04
- CUDA 12.8
- Docker с NVIDIA Runtime
- Kubernetes 1.25+
- Helm 3.x

## Лицензирование

```plain text
Copyright (c) 2025 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. 
See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT.
```
