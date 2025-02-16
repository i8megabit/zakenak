# Ƶakenak™® GitOps Repository

```ascii
```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

Should Harbour?	No.
```
## Версия
1.3.2

## Описание
Платформа для оркестрации GPU-ускоренных сервисов в среде WSL2, обеспечивающая:
- Автоматическое развертывание AI компонентов через Helm
- Оптимизированную интеграцию с NVIDIA GPU
- Управление сертификатами и безопасностью
- Мониторинг и оптимизацию производительности LLM моделей

## Компоненты системы

### Core Services
- cert-manager: Управление TLS сертификатами
	- Автоматическое обновление
	- Интеграция с локальным CA
	- Поддержка wildcard сертификатов

- local-ca: Локальный центр сертификации
	- Генерация корневых сертификатов
	- Управление цепочками доверия
	- Интеграция с cert-manager

- sidecar-injector: Инжекция TLS прокси
	- Автоматическая инжекция сайдкаров
	- Терминация TLS
	- Мониторинг состояния

### AI Services
- ollama: LLM сервер с GPU-акселерацией
	- Оптимизация GPU использования
	- Управление моделями
	- Поддержка deepseek-r1:14b
	- Конфигурация CUDA параметров

- open-webui: Веб-интерфейс для Ollama
	- Интеграция с LLM сервером
	- Управление контекстом
	- Оптимизация памяти
	- Кастомные промпты

### Infrastructure
- NVIDIA device plugin для WSL2
	- Управление GPU ресурсами
	- Мониторинг устройств
	- Оптимизация производительности

- CoreDNS с поддержкой .prod.local зоны
	- Резолвинг внутренних сервисов
	- Интеграция с Ingress
	- Кастомные записи DNS

- Ingress контроллер с TLS
	- TLS терминация
	- Маршрутизация трафика
	- Балансировка нагрузки

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
│   ├── cert-manager/     # Управление сертификатами
│   ├── local-ca/         # Локальный центр сертификации
│   ├── ollama/          # LLM сервер
│   ├── open-webui/      # Веб-интерфейс
│   └── sidecar-injector/ # Инжектор TLS сайдкаров
├── tools/               # Инструменты развертывания
│   ├── connectivity-check/ # Проверка связности
│   ├── helm-deployer/    # Деплой чартов
│   ├── k8s-kind-setup/  # Настройка кластера
│   ├── reset-wsl/       # Сброс WSL
│   └── zakenak/         # Основной инструмент
└── docs/               # Документация
		├── ARCHITECTURE.md  # Архитектура системы
		├── DEPLOYMENT.md    # Инструкции по развертыванию
		├── GPU-SETUP.md     # Настройка GPU
		├── MONITORING.md    # Мониторинг системы
		└── SECURITY.md      # Безопасность
```

## Документация
- [Архитектура](docs/ARCHITECTURE.md) - Детальное описание архитектуры системы
- [Развертывание](docs/DEPLOYMENT.md) - Пошаговое руководство по установке
- [GPU настройка](docs/GPU-SETUP.md) - Настройка и оптимизация GPU
- [Мониторинг](docs/MONITORING.md) - Система мониторинга и метрики
- [Безопасность](docs/SECURITY.md) - Аспекты безопасности и защиты

## Безопасность
- TLS для всех сервисов с автоматическим обновлением
- Изоляция подов через Network Policies
- Контроль доступа к GPU через RBAC
- Аудит операций и логирование
- Сканирование уязвимостей

## Оптимизация производительности
- Управление размером батча для LLM
- Оптимизация CUDA параметров
- Профилирование GPU использования
- Кэширование запросов
- Эффективное управление памятью

## Лицензирование
Проект распространяется под модифицированной MIT лицензией с защитой торговой марки. Использование названия "Zakenak" требует письменного разрешения владельца.

## Поддержка
- Email: i8megabit@gmail.com
- GitHub Issues: [Создать issue](https://github.com/i8megabit/zakenak/issues)
- Документация: [Руководство пользователя](docs/)

```plain text
Copyright (c) 2024 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

The name "Zakenak" and associated branding are trademarks of @eberil and may not be used without express written permission.
```