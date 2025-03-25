# Руководство по использованию окружений в Zakenak

```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

Should Harbour?	No.
```

## Навигация
- [Главная страница](../README.md)
- Документация
  - [Руководство по развертыванию](DEPLOYMENT.md)
  - [GitOps подход](GITOPS.md)
  - [API Reference](api.md)
  - [Устранение неполадок](troubleshooting.md)
  - [GPU в WSL2](GPU-WSL.md)
  - [Использование Docker](DOCKER-USAGE.md)
  - [Настройка KUBECONFIG](KUBECONFIG.md)
  - [Мониторинг](MONITORING.md)
  - [Настройка сети](NETWORK-CONFIGURATION.md)
  - [Окружения](ENVIRONMENTS.md) (текущий документ)
  - [Настройка SSL](SSL-CONFIGURATION.md)
  - [Миграция и настройка WSL и Docker](WSL-DOCKER-MIGRATION.md)
- [Примеры](../examples/README.md)

## Введение

Zakenak поддерживает два основных окружения: разработки (dev) и продакшена (prod). Каждое окружение имеет свои особенности, настройки и предназначено для разных целей. Это руководство описывает различия между окружениями и способы их использования.

## Окружения

### Dev окружение

Dev окружение предназначено для разработки, тестирования и отладки:

#### Характеристики
- **Namespace**: Все компоненты устанавливаются в namespace `dev`
- **Домены**: Используются домены вида `*.dev.local`
- **SSL**: Используется локальный центр сертификации (Local CA)
- **Доступ**: Доступ только из локальной сети
- **Ресурсы**: Оптимизировано для разработки, меньшие лимиты ресурсов
- **Логирование**: Расширенное логирование для отладки
- **Безопасность**: Упрощенные настройки безопасности

#### Конфигурационные файлы
- `values.yaml` - стандартные файлы конфигурации для dev окружения
- `values.dev.yaml` - специфичные настройки для dev окружения (если требуется)

### Prod окружение

Prod окружение предназначено для промышленной эксплуатации:

#### Характеристики
- **Namespace**: Все компоненты устанавливаются в namespace `prod`
- **Домены**: Используются домены вида `*.eberil.ru`
- **SSL**: Используется Let's Encrypt для получения доверенных сертификатов
- **Доступ**: Доступ из интернета
- **Ресурсы**: Оптимизировано для производительности, более высокие лимиты ресурсов
- **Логирование**: Минимальное логирование для снижения нагрузки
- **Безопасность**: Строгие настройки безопасности

#### Конфигурационные файлы
- `values.prod.yaml` - файлы конфигурации для prod окружения

## Установка компонентов

### Dev окружение

```bash
# Установка cert-manager
helm upgrade --install \
    cert-manager ./helm-charts/cert-manager \
    --namespace dev \
    --create-namespace \
    --values ./helm-charts/cert-manager/values.dev.yaml

# Установка local-ca
helm upgrade --install \
    local-ca ./helm-charts/local-ca \
    --namespace dev \
    --values ./helm-charts/local-ca/values.yaml

# Установка Ollama
helm upgrade --install \
    ollama ./helm-charts/ollama \
    --namespace dev \
    --values ./helm-charts/ollama/values.yaml

# Установка Open WebUI
helm upgrade --install \
    open-webui ./helm-charts/open-webui \
    --namespace dev \
    --values ./helm-charts/open-webui/values.yaml
```

### Prod окружение

```bash
# Установка cert-manager
helm upgrade --install \
    cert-manager ./helm-charts/cert-manager \
    --namespace prod \
    --create-namespace \
    --values ./helm-charts/cert-manager/values.prod.yaml

# Установка local-ca (опционально, если требуется)
helm upgrade --install \
    local-ca ./helm-charts/local-ca \
    --namespace prod \
    --values ./helm-charts/local-ca/values.prod.yaml

# Установка Ollama
helm upgrade --install \
    ollama ./helm-charts/ollama \
    --namespace prod \
    --values ./helm-charts/ollama/values.prod.yaml

# Установка Open WebUI
helm upgrade --install \
    open-webui ./helm-charts/open-webui \
    --namespace prod \
    --values ./helm-charts/open-webui/values.prod.yaml
```

## Переключение между окружениями

### Ручное переключение

Для переключения между окружениями используйте соответствующие values-файлы:

```bash
# Для dev окружения
--values ./helm-charts/[chart]/values.yaml

# Для prod окружения
--values ./helm-charts/[chart]/values.prod.yaml
```

### Автоматическое переключение

Вы можете использовать переменную окружения `ENVIRONMENT` для автоматического переключения:

```bash
# Установка переменной окружения
export ENVIRONMENT=dev  # или prod

# Установка компонентов с учетом окружения
helm upgrade --install \
    cert-manager ./helm-charts/cert-manager \
    --namespace $ENVIRONMENT \
    --create-namespace \
    --values ./helm-charts/cert-manager/values.${ENVIRONMENT}.yaml
```

## Доступ к сервисам

### Dev окружение

В dev окружении все сервисы доступны по доменам вида `*.dev.local`:

- Ollama: https://ollama.dev.local
- Open WebUI: https://webui.dev.local
- Kubernetes Dashboard: https://dashboard.dev.local

Для доступа к этим доменам необходимо:
1. Установить корневой сертификат локального CA в браузер
2. Настроить локальный DNS или файл hosts

### Prod окружение

В prod окружении все сервисы доступны по доменам вида `*.eberil.ru`:

- Ollama: https://ollama.eberil.ru
- Open WebUI: https://webui.eberil.ru
- Kubernetes Dashboard: https://dashboard.eberil.ru

Для доступа к этим доменам необходимо:
1. Настроить DNS-записи у вашего DNS-провайдера
2. Настроить Let's Encrypt для получения сертификатов

## Настройка DNS

### Dev окружение

Для dev окружения необходимо настроить локальный DNS или файл hosts:

```bash
# Добавление записей в файл hosts
sudo bash -c 'cat >> /etc/hosts << EOF
127.0.0.1 ollama.dev.local
127.0.0.1 webui.dev.local
127.0.0.1 dashboard.dev.local
EOF'
```

### Prod окружение

Для prod окружения необходимо настроить DNS-записи у вашего DNS-провайдера:

1. Войдите в панель управления вашего DNS-провайдера
2. Создайте A-записи для доменов:
   - ollama.eberil.ru -> IP-адрес вашего сервера
   - webui.eberil.ru -> IP-адрес вашего сервера
   - dashboard.eberil.ru -> IP-адрес вашего сервера

## Настройка SSL

### Dev окружение

В dev окружении используется локальный центр сертификации (Local CA):

1. Установка cert-manager с self-signed issuer
2. Экспорт корневого сертификата
3. Установка корневого сертификата в браузер

Подробнее см. [Настройка SSL](SSL-CONFIGURATION.md#настройка-ssl-в-dev-окружении).

### Prod окружение

В prod окружении используется Let's Encrypt:

1. Установка cert-manager с Let's Encrypt issuer
2. Настройка DNS-провайдера для DNS-01 challenge
3. Автоматическое получение и обновление сертификатов

Подробнее см. [Настройка SSL](SSL-CONFIGURATION.md#настройка-ssl-в-prod-окружении).

## Мониторинг и логирование

### Dev окружение

В dev окружении рекомендуется использовать расширенное логирование:

```yaml
# Пример настройки логирования в dev окружении
logging:
  level: debug
  format: json
  output: stdout
```

### Prod окружение

В prod окружении рекомендуется использовать минимальное логирование:

```yaml
# Пример настройки логирования в prod окружении
logging:
  level: info
  format: json
  output: file
  file:
    path: /var/log/app.log
    maxSize: 100
    maxBackups: 3
```

## Безопасность

### Dev окружение

В dev окружении можно использовать упрощенные настройки безопасности:

```yaml
# Пример настройки безопасности в dev окружении
security:
  authentication:
    enabled: false
  authorization:
    enabled: false
  networkPolicy:
    enabled: false
```

### Prod окружение

В prod окружении необходимо использовать строгие настройки безопасности:

```yaml
# Пример настройки безопасности в prod окружении
security:
  authentication:
    enabled: true
    method: oauth2
  authorization:
    enabled: true
    rbac: true
  networkPolicy:
    enabled: true
    defaultDeny: true
```

## Лучшие практики

1. **Изоляция окружений**: Используйте разные namespace для dev и prod окружений
2. **Конфигурация как код**: Храните конфигурацию окружений в Git
3. **Автоматизация**: Используйте CI/CD для автоматического развертывания
4. **Тестирование**: Тестируйте изменения в dev окружении перед применением в prod
5. **Мониторинг**: Настройте мониторинг для обоих окружений
6. **Резервное копирование**: Регулярно создавайте резервные копии prod окружения
7. **Документация**: Поддерживайте актуальную документацию по окружениям

## Устранение неполадок

### Проблемы с доступом к доменам в dev окружении

1. Проверьте файл hosts:
   ```bash
   cat /etc/hosts | grep dev.local
   ```

2. Проверьте установку корневого сертификата:
   ```bash
   ./tools/k8s-kind-setup/setup-cert-manager/src/export-root-ca.sh --check
   ```

3. Проверьте статус сертификатов:
   ```bash
   kubectl get certificates -n dev
   ```

### Проблемы с сертификатами в prod окружении

1. Проверьте статус сертификатов:
   ```bash
   kubectl get certificates -n prod
   ```

2. Проверьте логи cert-manager:
   ```bash
   kubectl logs -n cert-manager -l app=cert-manager
   ```

3. Проверьте настройки DNS:
   ```bash
   dig +short ollama.eberil.ru
   ```

## Заключение

Правильное использование окружений позволяет эффективно разрабатывать, тестировать и эксплуатировать приложения в Kubernetes. Следуйте рекомендациям из этого руководства для настройки и использования dev и prod окружений в Zakenak.

```plain text
Copyright (c) 2025 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. 
See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT.
```