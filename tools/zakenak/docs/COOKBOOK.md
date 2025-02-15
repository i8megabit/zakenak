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
[def]: https://github.com/i8meg/zakenak/releases