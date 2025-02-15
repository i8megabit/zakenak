# Ƶakanak - Руководство по установке и использованию

## Содержание
1. [Введение](#введение)
2. [Установка](#установка)Docker Desktop - WSL distro te
3. [Конфигурация](#конфигурация)
4. [Основные операции](#основные-операции)
5. [Продвинутые сценарии](#продвинутые-сценарии)
6. [Устранение неполадок](#устранение-неполадок)

## Введение

Ƶakanak (чаканак) - это элегантный инструмент для GitOps и деплоя, разработанный для максимальной эффективности и простоты использования. Основные области применения:

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
git clone https://github.com/i8meg/zakanak
cd zakanak

# Сборка
go build -o zakanak

# Установка бинарного файла
sudo mv zakanak /usr/local/bin/
chmod +x /usr/local/bin/zakanak

# Проверка установки
zakanak version
```

## Конфигурация

### Базовая конфигурация
Создайте файл `zakanak.yaml` в корне проекта:

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
zakanak converge

# Конвергенция с дополнительными опциями
zakanak converge --timeout 10m --debug
```

### 2. Сборка образов
```bash
# Сборка всех образов
zakanak build

# Сборка с GPU
zakanak build --gpu-enabled --gpu-memory 8Gi

# Сборка конкретного образа
zakanak build --target api-service
```

### 3. Деплой в кластер
```bash
# Полный деплой
zakanak deploy

# Деплой конкретного чарта
zakanak deploy --chart myapp

# Обновление с новыми значениями
zakanak deploy --values values-prod.yaml
```

### 4. Очистка ресурсов
```bash
# Очистка всех ресурсов
zakanak clean

# Очистка конкретного namespace
zakanak clean --namespace prod
```

## Продвинутые сценарии

### 1. Интеграция с CI/CD
```yaml
# GitLab CI
deploy:
	script:
		- zakanak converge --timeout 15m
	rules:
		- if: $CI_COMMIT_BRANCH == "main"
```

### 2. Мониторинг состояния
```bash
# Проверка статуса
zakanak status

# Получение логов
zakanak logs --component api-service
```

### 3. Работа с GPU
```bash
# Проверка доступности GPU
zakanak gpu status

# Оптимизация параметров GPU
zakanak gpu optimize --model deepseek-r1:14b
```

## Устранение неполадок

### Общие проблемы
1. **Ошибка подключения к кластеру**
```bash
# Проверка доступа
zakanak cluster-info

# Обновление креденшелов
zakanak auth refresh
```

2. **Проблемы с GPU**
```bash
# Проверка драйверов
zakanak gpu check-drivers

# Переустановка runtime
zakanak gpu setup-runtime
```

3. **Ошибки сборки**
```bash
# Очистка кэша
zakanak build clean-cache

# Отладочная сборка
zakanak build --debug --verbose
```

### Логи и отладка
```bash
# Включение отладочного режима
export ZAKANAK_DEBUG=true
zakanak converge

# Сбор диагностической информации
zakanak diagnose > diagnostics.log
```

## Дополнительные ресурсы
- [Cookbook](COOKBOOK.md)
- [API Reference](API.md)
- [Примеры конфигураций](examples/)