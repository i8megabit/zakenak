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


# Безопасность Ƶakenak™®

```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

Should Harbour?	No.
```
## Обзор системы безопасности

### Архитектура безопасности
- Многоуровневая модель защиты
- Изоляция компонентов в WSL2
- Принцип наименьших привилегий
- Защита GPU ресурсов NVIDIA

## TLS/SSL Защита

### Сертификаты
```yaml
# Пример конфигурации cert-manager
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: zakenak-cert
spec:
  secretName: zakenak-tls-secret
  duration: 2160h # 90 дней
  renewBefore: 360h # 15 дней
  privateKey:
    algorithm: ECDSA
    size: 256
```

### Управление сертификатами
1. Автоматическое обновление через cert-manager
2. Мониторинг срока действия сертификатов
3. Автоматическая ротация ключей
4. Безопасное хранение в Kubernetes secrets

## Сетевая безопасность

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: zakenak-default-deny
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### Ingress Security
- TLS терминация через NGINX Ingress
- Rate limiting для API endpoints
- WAF интеграция для веб-сервисов
- DDoS защита на уровне Ingress

## Безопасность GPU

### Изоляция ресурсов NVIDIA
```yaml
resources:
	limits:
		nvidia.com/gpu: 1
		memory: "8Gi"
		cpu: "2"
	requests:
		nvidia.com/gpu: 1
		memory: "4Gi"
		cpu: "1"
```

### NVIDIA Security в WSL2
1. Изоляция драйверов CUDA 12.8+
2. Защита доступа к GPU через device plugin
3. Мониторинг использования GPU
4. Аудит доступа к CUDA ресурсам

## Аутентификация и авторизация

### RBAC для GPU доступа
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: zakenak-gpu-user
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
```

### Service Accounts
- Минимальные привилегии для сервисов
- Автоматическая ротация токенов
- Подробный аудит доступа к GPU

## Мониторинг безопасности

### Логирование
- Централизованный сбор логов
- Структурированный JSON формат
- Политика хранения логов 30 дней
- Аудит доступа к GPU ресурсам

### Алертинг
1. Обнаружение аномалий в доступе
2. Мониторинг состояния сертификатов
3. Контроль нарушений Network Policy
4. Отслеживание инцидентов с GPU

## Безопасность данных

### Шифрование
- Шифрование данных в WSL2
- TLS для всех внешних коммуникаций
- Управление ключами через Kubernetes
- Регулярная ротация ключей

### Резервное копирование
1. Шифрованные резервные копии
2. Безопасное хранение бэкапов
3. Регулярное тестирование восстановления
4. Политика хранения бэкапов 90 дней

## Compliance

### Стандарты
- GDPR для обработки данных
- ISO 27001 практики
- SOC 2 для облачных сервисов
- PCI DSS при необходимости

### Аудит
1. Ежеквартальные проверки безопасности
2. Подробная отчетность
3. Своевременное исправление уязвимостей
4. Полная документация изменений

## Реагирование на инциденты

### План реагирования
1. Автоматическое обнаружение
2. Классификация по приоритетам
3. Изоляция затронутых компонентов
4. Устранение причин инцидента
5. Восстановление работоспособности

### Процедуры
- Четкая схема эскалации
- Оповещение ответственных лиц
- Документирование всех действий
- Постмортем анализ

## Лучшие практики

### Разработка
1. Secure coding guidelines
2. Обязательный code review
3. Сканирование зависимостей
4. Проверка безопасности контейнеров

### Эксплуатация
- Регулярные обновления CUDA/драйверов
- Управление патчами безопасности
- Hardening конфигурации WSL2
- Регулярный аудит доступов

## GPG Подпись Коммитов

### Автоматическая настройка
Для автоматической настройки GPG используйте скрипт:
```bash
./scripts/setup-gpg.sh
```

### Ручная настройка

#### 1. Установка GPG
```bash
sudo apt-get update
sudo apt-get install -y gnupg2
```

#### 2. Генерация ключа
```bash
gpg --full-generate-key
```
При генерации:
- Выберите RSA and RSA (default)
- Размер ключа: 4096 бит
- Срок действия: 0 = бессрочно
- Укажите ваше имя и email

#### 3. Получение ID ключа
```bash
gpg --list-secret-keys --keyid-format=long
```

#### 4. Настройка Git
```bash
git config --global user.signingkey YOUR_KEY_ID
git config --global commit.gpgsign true
```

#### 5. Экспорт публичного ключа
```bash
gpg --armor --export YOUR_KEY_ID
```

#### 6. Добавление в GitHub
1. Скопируйте весь вывод команды экспорта
2. Перейдите в GitHub Settings -> SSH and GPG keys
3. Нажмите "New GPG key"
4. Вставьте скопированный ключ

### Проверка настройки
```bash
# Создание подписанного коммита
git commit -S -m "Тестовый подписанный коммит"

# Проверка подписи
git verify-commit HEAD
```

### Устранение проблем

#### Ошибка "secret key not available"
```bash
gpg --list-secret-keys
git config --global user.signingkey YOUR_KEY_ID
```

#### Ошибка "gpg: signing failed: Inappropriate ioctl for device"
```bash
export GPG_TTY=$(tty)
```
Добавьте эту строку в ~/.bashrc или ~/.zshrc

## Контакты

### Security Team
- Email: i8megabit@gmail.com
- Emergency: +X XXX XXX XX XX

### Reporting
1. Программа responsible disclosure
2. Bug bounty для критических уязвимостей
3. Публикация security advisories
4. Отслеживание CVE в компонентах