# Подробное руководство по использованию Helm Chart для управления резюме на hh.ru

## Содержание

1. [Введение](#введение)
2. [Архитектура решения](#архитектура-решения)
3. [Подготовка к установке](#подготовка-к-установке)
4. [Установка](#установка)
5. [Детальная конфигурация](#детальная-конфигурация)
6. [Сценарии использования](#сценарии-использования)
7. [Мониторинг и обслуживание](#мониторинг-и-обслуживание)
8. [Устранение неполадок](#устранение-неполадок)
9. [Часто задаваемые вопросы](#часто-задаваемые-вопросы)
10. [Дополнительные ресурсы](#дополнительные-ресурсы)

## Введение

Helm Chart `hh-resume` предназначен для автоматизации процесса управления резюме на платформе hh.ru с использованием Kubernetes. Данное решение позволяет поддерживать актуальность вашего резюме без необходимости ручного обновления, что особенно полезно для специалистов, которые хотят сохранять видимость своего профиля для потенциальных работодателей.

### Зачем это нужно?

На платформе hh.ru резюме, которые не обновлялись в течение длительного времени, постепенно теряют свою позицию в результатах поиска работодателей. Регулярное обновление резюме помогает:

- Поддерживать высокую позицию в результатах поиска
- Демонстрировать активность на рынке труда
- Увеличивать количество просмотров резюме работодателями
- Получать больше предложений о работе

### Основные возможности

- **Автоматическое обновление** - настраиваемое расписание обновления резюме
- **Веб-интерфейс** - мониторинг статуса и управление настройками
- **Безопасность** - защищенное хранение учетных данных
- **Масштабируемость** - возможность управления несколькими резюме
- **Логирование** - отслеживание истории обновлений
- **Гибкая настройка** - адаптация под различные сценарии использования

## Архитектура решения

Решение состоит из следующих компонентов:

1. **Deployment** - основное приложение с веб-интерфейсом для мониторинга и управления
2. **CronJob** - периодическое задание для обновления резюме по расписанию
3. **ConfigMap** - конфигурация приложения и скрипты обновления
4. **Secret** - безопасное хранение API-токенов и идентификаторов резюме
5. **PersistentVolumeClaim** - хранение данных и истории обновлений
6. **Service** - доступ к веб-интерфейсу внутри кластера
7. **Ingress** - доступ к веб-интерфейсу извне кластера
8. **NetworkPolicy** - контроль сетевого доступа

### Схема взаимодействия компонентов

```
                    ┌─────────────┐
                    │   Ingress   │
                    └──────┬──────┘
                           │
                           ▼
┌─────────────┐     ┌─────────────┐
│  ConfigMap  │◄────┤   Service   │
└──────┬──────┘     └──────┬──────┘
       │                   │
       ▼                   ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   CronJob   │     │ Deployment  │◄────┤   Secret    │
└──────┬──────┘     └──────┬──────┘     └─────────────┘
       │                   │
       └────────┬──────────┘
                │
                ▼
        ┌─────────────────┐
        │ PersistentVolume│
        └─────────────────┘
                │
                ▼
          ┌───────────┐
          │  hh.ru API│
          └───────────┘
```

## Подготовка к установке

### Требования к системе

- Kubernetes кластер версии 1.19+
- Helm версии 3.2.0+
- Доступ к API hh.ru (учетная запись и API-токен)
- Идентификатор резюме для управления

### Получение API-токена hh.ru

1. Зарегистрируйтесь или войдите в свой аккаунт на [hh.ru](https://hh.ru)
2. Перейдите в раздел "Настройки" -> "Интеграции" -> "API доступ"
3. Создайте новое приложение, если у вас его еще нет
4. Получите OAuth-токен, следуя инструкциям на странице
5. Запишите полученный токен - он понадобится при установке

### Получение идентификатора резюме

1. Откройте свое резюме на hh.ru
2. В адресной строке браузера вы увидите URL вида `https://hh.ru/resume/XXXXXXXX`
3. Часть `XXXXXXXX` - это идентификатор вашего резюме
4. Запишите этот идентификатор - он понадобится при установке

### Сборка Docker образа

Для работы чарта требуется Docker образ `ghcr.io/i8megabit/hh-resume-updater`. Если образ недоступен в публичном репозитории или вы хотите использовать собственную версию, вы можете собрать его локально:

```bash
# Перейдите в директорию с Dockerfile
cd helm-charts/hh-resume/docker

# Запустите скрипт сборки образа
./build-image.sh
```

Скрипт проверит наличие образа локально и, если его нет, соберет его. После сборки образ будет доступен для использования в Kubernetes.

#### Настройка собственного образа

Если вы хотите использовать собственный образ с другим именем или тегом, вы можете изменить параметры в файле `build-image.sh` или указать свои значения при установке чарта:

```yaml
# my-values.yaml
image:
  repository: my-registry/my-hh-resume-updater
  tag: v1.0.0
  pullPolicy: IfNotPresent
```

## Установка

### Подготовка секретов

Перед установкой чарта необходимо создать секрет с учетными данными для доступа к API hh.ru:

```bash
kubectl create secret generic hh-credentials \
  --namespace=my-resume \
  --from-literal=api-token=ВАШ_API_ТОКЕН \
  --from-literal=resume-id=ИДЕНТИФИКАТОР_РЕЗЮМЕ
```

### Создание файла конфигурации

Создайте файл `my-values.yaml` с вашими настройками:

```yaml
# my-values.yaml
release:
  namespace: my-resume

image:
  repository: hhresume/api-updater
  tag: latest

deployment:
  schedule: "0 9 * * 1-5"  # Обновление каждый будний день в 9:00
  
service:
  type: ClusterIP
  port: 80
  targetPort: 8080

ingress:
  enabled: false  # Измените на true, если нужен внешний доступ
```

### Установка чарта

```bash
# Создание пространства имен
kubectl create namespace my-resume

# Установка чарта
helm install my-resume ./helm-charts/hh-resume \
  --namespace my-resume \
  --values my-values.yaml
```

### Проверка установки

```bash
# Проверка всех созданных ресурсов
kubectl get all -n my-resume -l app=hh-resume

# Проверка статуса CronJob
kubectl get cronjobs -n my-resume
```

## Детальная конфигурация

### Полный список параметров конфигурации

#### Основные параметры

| Параметр | Описание | Тип | Значение по умолчанию |
|----------|----------|-----|------------------------|
| `release.namespace` | Пространство имен для установки | string | `default` |
| `image.repository` | Репозиторий образа | string | `hhresume/api-updater` |
| `image.tag` | Тег образа | string | `latest` |
| `image.pullPolicy` | Политика загрузки образа | string | `IfNotPresent` |

#### Настройки развертывания

| Параметр | Описание | Тип | Значение по умолчанию |
|----------|----------|-----|------------------------|
| `deployment.replicas` | Количество реплик приложения | int | `1` |
| `deployment.schedule` | Расписание обновления резюме (cron-формат) | string | `0 */12 * * *` |
| `deployment.env` | Дополнительные переменные окружения | list | См. values.yaml |
| `deployment.resources.limits.cpu` | Лимит CPU | string | `200m` |
| `deployment.resources.limits.memory` | Лимит памяти | string | `256Mi` |
| `deployment.resources.requests.cpu` | Запрос CPU | string | `100m` |
| `deployment.resources.requests.memory` | Запрос памяти | string | `128Mi` |

#### Настройки сервиса

| Параметр | Описание | Тип | Значение по умолчанию |
|----------|----------|-----|------------------------|
| `service.type` | Тип сервиса | string | `ClusterIP` |
| `service.port` | Порт сервиса | int | `80` |
| `service.targetPort` | Целевой порт в контейнере | int | `8080` |

#### Настройки Ingress

| Параметр | Описание | Тип | Значение по умолчанию |
|----------|----------|-----|------------------------|
| `ingress.enabled` | Включить/выключить Ingress | bool | `false` |
| `ingress.className` | Класс Ingress-контроллера | string | `nginx` |
| `ingress.annotations` | Аннотации для Ingress | object | `{}` |
| `ingress.hosts` | Хосты для Ingress | list | См. values.yaml |
| `ingress.tls` | Настройки TLS для Ingress | list | `[]` |

#### Настройки хранилища

| Параметр | Описание | Тип | Значение по умолчанию |
|----------|----------|-----|------------------------|
| `persistence.enabled` | Включить/выключить постоянное хранилище | bool | `true` |
| `persistence.accessModes` | Режимы доступа к хранилищу | list | `["ReadWriteOnce"]` |
| `persistence.size` | Размер хранилища | string | `1Gi` |
| `persistence.storageClass` | Класс хранилища | string | `""` |

#### Настройки сетевой политики

| Параметр | Описание | Тип | Значение по умолчанию |
|----------|----------|-----|------------------------|
| `networkPolicy.enabled` | Включить/выключить сетевую политику | bool | `true` |
| `networkPolicy.allowedNamespaces` | Пространства имен, которым разрешен доступ | list | `["default", "kube-system"]` |

### Настройка расписания обновления

Расписание обновления резюме настраивается в формате cron. Примеры:

- `0 */12 * * *` - каждые 12 часов (в 00:00 и 12:00)
- `0 9 * * 1-5` - каждый будний день в 9:00
- `0 9,18 * * *` - каждый день в 9:00 и 18:00
- `0 9 1,15 * *` - 1-го и 15-го числа каждого месяца в 9:00

### Настройка веб-интерфейса

Для включения веб-интерфейса необходимо настроить Ingress:

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
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

## Сценарии использования

### Базовое обновление резюме

Самый простой сценарий - автоматическое обновление одного резюме по расписанию:

```yaml
# my-values.yaml
release:
  namespace: resume-updater

deployment:
  schedule: "0 9 * * 1-5"  # Обновление каждый будний день в 9:00

persistence:
  enabled: true
  size: 1Gi
```

### Управление несколькими резюме

Для управления несколькими резюме можно установить несколько экземпляров чарта:

```bash
# Создание секрета для первого резюме
kubectl create secret generic resume1-credentials \
  --namespace=resume-manager \
  --from-literal=api-token=ТОКЕН_1 \
  --from-literal=resume-id=РЕЗЮМЕ_ID_1

# Создание секрета для второго резюме
kubectl create secret generic resume2-credentials \
  --namespace=resume-manager \
  --from-literal=api-token=ТОКЕН_2 \
  --from-literal=resume-id=РЕЗЮМЕ_ID_2

# Установка первого экземпляра
helm install resume1 ./helm-charts/hh-resume \
  --namespace resume-manager \
  --set release.namespace=resume-manager \
  --set deployment.env[0].name=HH_API_TOKEN \
  --set deployment.env[0].valueFrom.secretKeyRef.name=resume1-credentials \
  --set deployment.env[0].valueFrom.secretKeyRef.key=api-token \
  --set deployment.env[1].name=HH_RESUME_ID \
  --set deployment.env[1].valueFrom.secretKeyRef.name=resume1-credentials \
  --set deployment.env[1].valueFrom.secretKeyRef.key=resume-id

# Установка второго экземпляра
helm install resume2 ./helm-charts/hh-resume \
  --namespace resume-manager \
  --set release.namespace=resume-manager \
  --set deployment.env[0].name=HH_API_TOKEN \
  --set deployment.env[0].valueFrom.secretKeyRef.name=resume2-credentials \
  --set deployment.env[0].valueFrom.secretKeyRef.key=api-token \
  --set deployment.env[1].name=HH_RESUME_ID \
  --set deployment.env[1].valueFrom.secretKeyRef.name=resume2-credentials \
  --set deployment.env[1].valueFrom.secretKeyRef.key=resume-id
```

### Мониторинг через веб-интерфейс

Для мониторинга статуса резюме через веб-интерфейс:

```yaml
# my-values.yaml
release:
  namespace: resume-monitor

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
```

## Мониторинг и обслуживание

### Просмотр логов

```bash
# Логи основного приложения
kubectl logs -n <namespace> -l app=hh-resume

# Логи последнего запуска CronJob
kubectl logs -n <namespace> $(kubectl get pods -n <namespace> -l job-name=<job-name> -o name | head -n 1)

# Просмотр истории обновлений
kubectl exec -n <namespace> $(kubectl get pods -n <namespace> -l app=hh-resume -o name | head -n 1) -- cat /app/resume/update-history.log
```

### Проверка статуса CronJob

```bash
# Список всех CronJob
kubectl get cronjobs -n <namespace>

# Детальная информация о конкретном CronJob
kubectl describe cronjob <cronjob-name> -n <namespace>

# Список последних запусков
kubectl get jobs -n <namespace> -l app=hh-resume
```

### Ручной запуск обновления

```bash
# Создание Job из CronJob
kubectl create job --from=cronjob/<cronjob-name> manual-update -n <namespace>

# Проверка статуса
kubectl get job manual-update -n <namespace>

# Просмотр логов
kubectl logs -n <namespace> -l job-name=manual-update
```

### Обновление чарта

```bash
# Обновление чарта с новыми значениями
helm upgrade my-resume ./helm-charts/hh-resume \
  --namespace my-resume \
  --values my-values.yaml
```

## Устранение неполадок

### Распространенные проблемы и их решения

#### 1. Ошибка аутентификации API

**Симптомы:**
- В логах CronJob видны ошибки аутентификации
- Сообщения об истечении срока действия токена

**Решение:**
1. Проверьте правильность API-токена:
   ```bash
   kubectl get secret hh-credentials -n <namespace> -o jsonpath='{.data.api-token}' | base64 --decode
   ```
2. Обновите токен, если он истек:
   ```bash
   kubectl patch secret hh-credentials -n <namespace> -p '{"data":{"api-token":"'$(echo -n 'НОВЫЙ_ТОКЕН' | base64)'"}}'
   ```

#### 2. CronJob не запускается

**Симптомы:**
- Отсутствуют записи о запусках в истории CronJob
- Нет новых записей в логах

**Решение:**
1. Проверьте правильность формата расписания:
   ```bash
   kubectl get cronjob <cronjob-name> -n <namespace> -o jsonpath='{.spec.schedule}'
   ```
2. Проверьте статус CronJob:
   ```bash
   kubectl describe cronjob <cronjob-name> -n <namespace>
   ```
3. Запустите задание вручную для проверки:
   ```bash
   kubectl create job --from=cronjob/<cronjob-name> test-run -n <namespace>
   ```

#### 3. Проблемы с сетевой политикой

**Симптомы:**
- Ошибки подключения к API hh.ru
- Таймауты при обновлении резюме

**Решение:**
1. Временно отключите сетевую политику для диагностики:
   ```yaml
   networkPolicy:
     enabled: false
   ```
2. Проверьте доступность API hh.ru из пода:
   ```bash
   kubectl exec -it $(kubectl get pods -n <namespace> -l app=hh-resume -o name | head -n 1) -n <namespace> -- curl -v https://api.hh.ru/
   ```

#### 4. Проблемы с хранилищем

**Симптомы:**
- Ошибки записи в лог-файл
- Сообщения о нехватке места

**Решение:**
1. Проверьте статус PVC:
   ```bash
   kubectl describe pvc <pvc-name> -n <namespace>
   ```
2. Увеличьте размер хранилища:
   ```yaml
   persistence:
     size: 5Gi
   ```

### Диагностика с помощью kubectl

```bash
# Проверка всех ресурсов
kubectl get all -n <namespace> -l app=hh-resume

# Проверка событий в пространстве имен
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Проверка описания пода для выявления проблем
kubectl describe pod <pod-name> -n <namespace>

# Проверка конфигурации
kubectl get configmap <configmap-name> -n <namespace> -o yaml
```

## Часто задаваемые вопросы

### 1. Как часто нужно обновлять резюме на hh.ru?

Оптимальная частота обновления резюме на hh.ru - один раз в 1-3 дня. Слишком частое обновление может быть расценено как спам, а слишком редкое не даст нужного эффекта для поддержания видимости резюме.

### 2. Безопасно ли хранить API-токен в Kubernetes?

Да, если правильно настроить безопасность. В данном чарте API-токен хранится в Kubernetes Secret, который шифруется при хранении в etcd. Дополнительно можно использовать решения вроде HashiCorp Vault или Sealed Secrets для повышения безопасности.

### 3. Можно ли использовать чарт для нескольких резюме с одним API-токеном?

Да, один API-токен может использоваться для управления несколькими резюме. Для этого нужно установить несколько экземпляров чарта с разными идентификаторами резюме, но одинаковым API-токеном.

### 4. Что делать, если API hh.ru изменится?

В случае изменения API hh.ru потребуется обновить скрипт обновления резюме в ConfigMap. Это можно сделать с помощью команды:

```bash
helm upgrade my-resume ./helm-charts/hh-resume \
  --namespace my-resume \
  --set-file configMapData."update-resume\.sh"=new-script.sh
```

### 5. Как отслеживать эффективность обновлений?

Для отслеживания эффективности можно:
- Регулярно проверять статистику просмотров резюме в личном кабинете hh.ru
- Настроить дополнительный скрипт для сбора статистики через API
- Интегрировать решение с системами мониторинга для отслеживания успешных обновлений

## Дополнительные ресурсы

### Документация API hh.ru

- [Официальная документация API hh.ru](https://dev.hh.ru/)
- [Документация по работе с резюме](https://github.com/hhru/api/blob/master/docs/resumes.md)
- [Авторизация в API](https://github.com/hhru/api/blob/master/docs/authorization.md)

### Полезные ссылки по Kubernetes

- [Документация Helm](https://helm.sh/docs/)
- [Kubernetes CronJobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Kubernetes NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

### Сообщество и поддержка

- [GitHub проекта](https://github.com/eberil/hh-resume-manager)
- [Telegram-канал с обновлениями](https://t.me/hhresume_updates)
- [Группа поддержки](https://t.me/hhresume_support)