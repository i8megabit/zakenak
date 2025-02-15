```ascii
	 ______     _                      _    
	|___  /    | |                    | |   
	   / / __ _| |  _ _   ___     ___ | |  _
	  / / / _` | |/ / _`||  _ \ / _` || |/ /
	 / /_| (_| |  < by_Ӗberil| | (_| ||   < 
	/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\
  
					  	Should Harbour?				
# [ƵakӖnak™®](https://dic.academic.ru/dic.nsf/dic_synonims/390396/%D1%87%D0%B0%D0%BA%D0%B0%D0%BD%D0%B0%D0%BAчаканак "др.-чув. чӑканӑк — бухта, залив")
[![Go Report Card](https://goreportcard.com/badge/github.com/i8meg/zakenak)](https://goreportcard.com/report/github.com/i8meg/zakenak)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/i8meg/zakenak)][def]

## Содержание
1. [Введение](#введение)
2. [Установка](#установка)Docker Desktop - WSL distro te
3. [Конфигурация](#конфигурация)
4. [Основные операции](#основные-операции)
5. [Продвинутые сценарии](#продвинутые-сценарии)
6. [Устранение неполадок](#устранение-неполадок)

## Введение

Ƶakanak (Чаканак) - это инструмент для GitOps и деплоя, разработанный для максимальной эффективности и простоты использования. Основные области применения:

### 1. GitOps автоматизация
- Синхронизация состояния кластера с Git-репозиторием
- Автоматическое обнаружение и применение изменений
- Контроль версий инфраструктуры

### 2. Управление контейнерами
- Сборка Docker образов с поддержкой GPU
- Оптимизация многоэтапных сборок
- Интеграция с container registry

### 3. Деплой в Kubernetes
- Управление Helm чартами
- Конвергенция состояния кластера
- Автоматическое восстановление при сбоях

### 4. Интеграция с WSL2 и GPU
- Нативная поддержка NVIDIA GPU
- Оптимизация для работы в WSL2
- Автоматическая настройка драйверов

## Установка

### Предварительные требования
- Go 1.21+
- Git
- Docker
- Kubernetes кластер
- WSL2 (для Windows)
- NVIDIA GPU + драйверы (опционально)

### Установка из исходного кода
```bash
# Клонирование репозитория
git clone https://github.com/i8meg/zakenak
cd zakenak

# Сборка
go build -o zakenak

# Установка бинарного файла
sudo mv zakenak /usr/local/bin/
chmod +x /usr/local/bin/zakenak

# Проверка установки
zakenak version
```

## Конфигурация

### Базовая конфигурация
Создайте файл `zakenak.yaml` в корне проекта:

```yaml
project: myapp
environment: prod

registry:
	url: registry.local
	username: ${REGISTRY_USER}  # Из переменных окружения
	password: ${REGISTRY_PASS}  # Из переменных окружения

deploy:
	namespace: prod
	charts:
		- ./helm/myapp
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

git:
	branch: main
	paths:
		- helm/
		- kubernetes/
	strategy: fast-forward
```

## Основные операции

### 1. Конвергенция состояния
```bash
# Полная конвергенция
zakenak converge

# Конвергенция с дополнительными опциями
zakenak converge --timeout 10m --debug
```

### 2. Сборка образов
```bash
# Сборка всех образов
zakenak build

# Сборка с GPU
zakenak build --gpu-enabled --gpu-memory 8Gi

# Сборка конкретного образа
zakenak build --target api-service
```

### 3. Деплой в кластер
```bash
# Полный деплой
zakenak deploy

# Деплой конкретного чарта
zakenak deploy --chart myapp

# Обновление с новыми значениями
zakenak deploy --values values-prod.yaml
```

### 4. Очистка ресурсов
```bash
# Очистка всех ресурсов
zakenak clean

# Очистка конкретного namespace
zakenak clean --namespace prod
```

## Продвинутые сценарии

### 1. Интеграция с CI/CD
```yaml
# GitLab CI
deploy:
	script:
		- zakenak converge --timeout 15m
	rules:
		- if: $CI_COMMIT_BRANCH == "main"
```

### 2. Мониторинг состояния
```bash
# Проверка статуса
zakenak status

# Получение логов
zakenak logs --component api-service
```

### 3. Работа с GPU
```bash
# Проверка доступности GPU
zakenak gpu status

# Оптимизация параметров GPU
zakenak gpu optimize --model deepseek-r1:14b
```

## Устранение неполадок

### Общие проблемы
1. **Ошибка подключения к кластеру**
```bash
# Проверка доступа
zakenak cluster-info

# Обновление креденшелов
zakenak auth refresh
```

2. **Проблемы с GPU**
```bash
# Проверка драйверов
zakenak gpu check-drivers

# Переустановка runtime
zakenak gpu setup-runtime
```

3. **Ошибки сборки**
```bash
# Очистка кэша
zakenak build clean-cache

# Отладочная сборка
zakenak build --debug --verbose
```

### Логи и отладка
```bash
# Включение отладочного режима
export ZAKANAK_DEBUG=true
zakenak converge

# Сбор диагностической информации
zakenak diagnose > diagnostics.log
```

## Дополнительные ресурсы
- [Cookbook](COOKBOOK.md)
- [API Reference](API.md)
- [Примеры конфигураций](examples/)

[def]: https://github.com/i8meg/zakenak/releases