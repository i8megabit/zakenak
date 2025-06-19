# Helm Chart для управления резюме на hh.ru

## Обзор

Данный Helm Chart предназначен для автоматизации управления резюме на платформе hh.ru с использованием Kubernetes. Чарт позволяет развернуть приложение, которое взаимодействует с API hh.ru для автоматического обновления резюме, что помогает поддерживать его активность и видимость для работодателей.

## Возможности

- **Автоматическое обновление резюме** - регулярное обновление резюме по расписанию через CronJob
- **Веб-интерфейс** - опциональный веб-интерфейс для мониторинга статуса резюме и управления настройками
- **Безопасное хранение учетных данных** - использование Kubernetes Secrets для хранения API-токенов и идентификаторов резюме
- **Постоянное хранилище данных** - сохранение истории обновлений и статистики в постоянном хранилище
- **Гибкая настройка сетевой политики** - контроль доступа к API hh.ru и другим внешним сервисам
- **Масштабируемость** - возможность управления несколькими резюме с помощью одного развертывания

## Предварительные требования

- Kubernetes кластер версии 1.19+
- Установленный Helm версии 3.2.0+
- Учетная запись на hh.ru и API-токен
- Идентификатор резюме, которым нужно управлять

## Сборка Docker образа

Для работы чарта требуется Docker образ `ghcr.io/i8megabit/hh-resume-updater`. Если образ недоступен в публичном репозитории, вы можете собрать его локально:

```bash
# Перейдите в директорию с Dockerfile
cd helm-charts/hh-resume/docker

# Запустите скрипт сборки образа
./build-image.sh
```

Скрипт проверит наличие образа локально и, если его нет, соберет его. После сборки образ будет доступен для использования в Kubernetes.

## Установка

### Подготовка секретов

Перед установкой чарта необходимо создать секрет с учетными данными для доступа к API hh.ru:

```bash
kubectl create secret generic hh-credentials \
  --from-literal=api-token=ВАШ_API_ТОКЕН \
  --from-literal=resume-id=ИДЕНТИФИКАТОР_РЕЗЮМЕ
```

### Установка чарта

```bash
helm install my-resume ./helm-charts/hh-resume \
  --namespace my-resume \
  --create-namespace \
  --values my-values.yaml
```

## Конфигурация

Чарт можно настроить с помощью файла values.yaml. Ниже приведены основные параметры конфигурации:

### Основные параметры

| Параметр | Описание | Значение по умолчанию |
|----------|----------|------------------------|
| `release.namespace` | Пространство имен для установки | `default` |
| `image.repository` | Репозиторий образа | `hhresume/api-updater` |
| `image.tag` | Тег образа | `latest` |
| `image.pullPolicy` | Политика загрузки образа | `IfNotPresent` |

### Настройки развертывания

| Параметр | Описание | Значение по умолчанию |
|----------|----------|------------------------|
| `deployment.replicas` | Количество реплик приложения | `1` |
| `deployment.schedule` | Расписание обновления резюме (cron-формат) | `0 */12 * * *` |
| `deployment.resources` | Ресурсы для контейнера | См. values.yaml |

### Настройки сервиса и Ingress

| Параметр | Описание | Значение по умолчанию |
|----------|----------|------------------------|
| `service.type` | Тип сервиса | `ClusterIP` |
| `service.port` | Порт сервиса | `80` |
| `ingress.enabled` | Включить/выключить Ingress | `false` |
| `ingress.className` | Класс Ingress-контроллера | `nginx` |
| `ingress.hosts` | Хосты для Ingress | См. values.yaml |

### Настройки хранилища

| Параметр | Описание | Значение по умолчанию |
|----------|----------|------------------------|
| `persistence.enabled` | Включить/выключить постоянное хранилище | `true` |
| `persistence.size` | Размер хранилища | `1Gi` |
| `persistence.storageClass` | Класс хранилища | `""` |

### Настройки сетевой политики

| Параметр | Описание | Значение по умолчанию |
|----------|----------|------------------------|
| `networkPolicy.enabled` | Включить/выключить сетевую политику | `true` |
| `networkPolicy.allowedNamespaces` | Пространства имен, которым разрешен доступ | `["default", "kube-system"]` |

## Примеры использования

### Базовая установка

```yaml
# my-values.yaml
release:
  namespace: resume-manager

image:
  repository: hhresume/api-updater
  tag: 1.0.0

deployment:
  schedule: "0 9 * * 1-5"  # Обновление каждый будний день в 9:00
```

### Установка с веб-интерфейсом

```yaml
# my-values.yaml
release:
  namespace: resume-manager

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: resume.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: resume-tls
      hosts:
        - resume.example.com
```

### Установка с настройкой ресурсов

```yaml
# my-values.yaml
deployment:
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 200m
      memory: 256Mi

persistence:
  size: 5Gi
  storageClass: "fast-ssd"
```

## Устранение неполадок

### Проверка статуса развертывания

```bash
kubectl get all -n <namespace> -l app=hh-resume
```

### Просмотр логов

```bash
# Логи основного приложения
kubectl logs -n <namespace> -l app=hh-resume

# Логи CronJob
kubectl logs -n <namespace> job/<job-name>
```

### Распространенные проблемы

1. **Ошибка аутентификации API**
   - Проверьте правильность API-токена в секрете `hh-credentials`
   - Убедитесь, что токен не истек

2. **CronJob не запускается**
   - Проверьте правильность формата расписания
   - Проверьте статус последних запусков: `kubectl get cronjobs -n <namespace>`

3. **Проблемы с сетевой политикой**
   - Если приложение не может подключиться к API hh.ru, проверьте настройки сетевой политики
   - Временно отключите сетевую политику для диагностики: `networkPolicy.enabled: false`

## Дополнительная информация

- [Документация API hh.ru](https://dev.hh.ru/)
- [Руководство по работе с резюме через API](https://github.com/hhru/api/blob/master/docs/resumes.md)
- [Исходный код проекта](https://github.com/eberil/hh-resume-manager)

## Лицензия

Copyright (c) 2025 Mikhail Eberil