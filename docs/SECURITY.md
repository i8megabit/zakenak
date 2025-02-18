# Безопасность Zakenak

```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

Should Harbour?	No.
```

## Модель безопасности

### Принципы
- Zero Trust Architecture
- Defense in Depth
- Принцип наименьших привилегий
- Изоляция компонентов
- Постоянный мониторинг

### Уровни защиты
1. Инфраструктурный уровень
   - WSL2 изоляция
   - Kubernetes security context
   - Network policies
   - Pod security standards

2. Уровень приложений
   - TLS везде
   - Аутентификация и авторизация
   - Валидация входных данных
   - Безопасная обработка ошибок

3. Уровень данных
   - Шифрование в состоянии покоя
   - Шифрование в транзите
   - Управление секретами
   - Аудит доступа

## Защита GPU ресурсов

### Базовая изоляция GPU
```yaml
# Пример Pod Security Context для GPU workload
apiVersion: v1
kind: Pod
metadata:
    name: gpu-workload
spec:
    securityContext:
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
        seccompProfile:
            type: RuntimeDefault
    containers:
    - name: gpu-container
        securityContext:
            allowPrivilegeEscalation: false
            capabilities:
                drop:
                - ALL
            readOnlyRootFilesystem: true
        resources:
            limits:
                nvidia.com/gpu: "1"
                memory: "8Gi"
                cpu: "2"
                nvidia.com/gpu-memory: "8Gi"
            requests:
                nvidia.com/gpu: "1"
                memory: "4Gi"
                cpu: "1"
        env:
        - name: NVIDIA_VISIBLE_DEVICES
          value: "all"
        - name: NVIDIA_DRIVER_CAPABILITIES
          value: "compute,utility"
        - name: CUDA_CACHE_DISABLE
          value: "1"
```

### Защита от криптомайнинга
1. Ограничение процессов:
```yaml
spec:
  containers:
  - name: gpu-container
    securityContext:
      procMount: Default
      seccompProfile:
        type: Localhost
        localhostProfile: "profiles/gpu-restrict.json"
```

2. Профиль Seccomp для GPU (profiles/gpu-restrict.json):
```json
{
    "defaultAction": "SCMP_ACT_ERRNO",
    "architectures": ["SCMP_ARCH_X86_64"],
    "syscalls": [
        {
            "names": [
                "read",
                "write",
                "openat",
                "close",
                "fstat",
                "mmap",
                "mprotect",
                "munmap",
                "rt_sigaction",
                "rt_sigprocmask",
                "ioctl",
                "nanosleep"
            ],
            "action": "SCMP_ACT_ALLOW"
        }
    ]
}
```

3. NetworkPolicy для GPU подов:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: gpu-pods-policy
spec:
  podSelector:
    matchLabels:
      gpu: "true"
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: prod
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: prod
    ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
```

### Мониторинг аномалий GPU
1. Prometheus правила для обнаружения аномалий:
```yaml
groups:
- name: gpu.rules
  rules:
  - alert: GPUHighUtilization
    expr: nvidia_gpu_duty_cycle > 95
    for: 15m
    labels:
      severity: warning
    annotations:
      description: "GPU {{$labels.gpu}} utilization > 95% for 15m"

  - alert: GPUAnomalousMemoryUsage
    expr: nvidia_gpu_memory_used_bytes / nvidia_gpu_memory_total_bytes * 100 > 90
    for: 10m
    labels:
      severity: warning
    annotations:
      description: "GPU {{$labels.gpu}} memory usage > 90% for 10m"

  - alert: GPUProcessCount
    expr: count(nvidia_gpu_processes) by (gpu) > 3
    for: 5m
    labels:
      severity: warning
    annotations:
      description: "Unusual number of processes on GPU {{$labels.gpu}}"
```

2. Автоматическое ограничение подозрительных подов:
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: gpu-pods-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      gpu: "true"
```

### Аудит использования GPU
1. Включение расширенного аудита в Kubernetes:
```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  resources:
  - group: ""
    resources: ["pods"]
    namespaces: ["prod"]
    verbs: ["create", "update", "patch", "delete"]
  - group: "nvidia.com"
    resources: ["gpus"]
    verbs: ["*"]
```

2. Логирование GPU событий:
```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    seccomp.security.alpha.kubernetes.io/pod: "docker/default"
    container.seccomp.security.alpha.kubernetes.io/gpu-container: "profiles/gpu-restrict"
    audit.k8s.io/gpu-monitor: "enabled"
```

### Дополнительные меры безопасности
1. Ограничение времени выполнения GPU задач:
```yaml
spec:
  activeDeadlineSeconds: 3600
  containers:
  - name: gpu-container
    resources:
      limits:
        nvidia.com/gpu-time: "3600s"
```

2. Квоты на использование GPU:
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: gpu-quota
spec:
  hard:
    requests.nvidia.com/gpu: "4"
    limits.nvidia.com/gpu: "4"
    requests.nvidia.com/gpu-memory: "32Gi"
    limits.nvidia.com/gpu-memory: "32Gi"
```

3. LimitRange для GPU подов:
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: gpu-limits
spec:
  limits:
  - type: Container
    defaultRequest:
      nvidia.com/gpu: "1"
      memory: "4Gi"
    default:
      nvidia.com/gpu: "1"
      memory: "8Gi"
    max:
      nvidia.com/gpu: "2"
      memory: "16Gi"
```

### NVIDIA Security
1. Device Plugin безопасность
     - Валидация устройств
     - Контроль доступа
     - Мониторинг использования
     - Изоляция ресурсов

2. Runtime Security
     - Контейнерная изоляция
     - Ограничение возможностей
     - Мониторинг процессов
     - Аудит операций

3. Memory Security
     - Изоляция памяти GPU
     - Очистка после использования
     - Мониторинг утечек
     - Защита от переполнения

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

```plain text
Copyright (c) 2025 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. 
See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT.
```