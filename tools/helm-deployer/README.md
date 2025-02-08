# Helm Chart Deployer

Версия: 1.0.0

Универсальный инструмент для автоматического деплоя Helm чартов в Kubernetes с поддержкой иерархии values и управлением порядком установки.

## Описание
Скрипт автоматизирует процесс деплоя Helm чартов, обеспечивая:
- Автоматическое определение параметров из values файлов
- Поддержку иерархии конфигураций
- Управление порядком установки чартов
- Валидацию чартов перед установкой
- Автоматическое создание namespace

## Структура проекта
```
helm-charts/
├── values.yaml           # Глобальные настройки для всех чартов
├── install-order.yaml    # Порядок установки чартов
├── chart1/              # Директория чарта
│   ├── values.yaml     # Настройки конкретного чарта
│   └── ...
└── chart2/
	├── values.yaml
	└── ...
```

## Иерархия Values
Скрипт поддерживает следующую иерархию values файлов (в порядке возрастания приоритета):
1. Глобальный values.yaml в корне helm-charts/
2. Values.yaml конкретного чарта
3. Values.{environment}.yaml для конкретного окружения

## Конфигурация чарта
Каждый чарт должен содержать values.yaml со следующей структурой:
```yaml
# Параметры релиза (обязательно)
release:
  name: my-release      # Имя релиза
  namespace: default    # Целевой namespace

# Остальные параметры чарта
config:
  ...
```

## Порядок установки
Для управления порядком установки создайте файл install-order.yaml:
```yaml
# Порядок установки чартов
charts:
- cert-manager
- ingress-nginx
- monitoring
```

## Использование

### Автоматический деплой всех чартов
```bash
./deploy-chart.sh
```

### Деплой с указанием окружения
```bash
./deploy-chart.sh -e production
```

### Деплой с отладкой
```bash
./deploy-chart.sh --debug
```

### Пробный запуск
```bash
./deploy-chart.sh --dry-run
```

## Требования
- Kubernetes кластер
- Helm 3.x
- kubectl
- yq
- bash

## Устранение неполадок

### Ошибка доступа к кластеру
```bash
# Проверьте подключение к кластеру
kubectl cluster-info

# Проверьте текущий контекст
kubectl config current-context
```

### Ошибка при валидации чарта
```bash
# Проверьте чарт вручную
helm lint ./helm-charts/my-chart

# Проверьте синтаксис values файла
yq eval . ./helm-charts/my-chart/values.yaml
```

### Проблемы с namespace
```bash
# Проверьте существующие namespace
kubectl get namespaces

# Создайте namespace вручную
kubectl create namespace my-namespace
```

## Примеры конфигурации

### Глобальный values.yaml
```yaml
global:
  environment: production
  domain: example.com

cert-manager:
  email: "admin@example.com"

monitoring:
  enabled: true
  retention: 30d
```

### Values чарта
```yaml
release:
  name: monitoring
  namespace: monitoring

config:
  persistence:
	enabled: true
	size: 10Gi
```

## Логи и отладка
Скрипт предоставляет подробный вывод о процессе установки:
- Зеленый текст: успешные операции
- Желтый текст: информационные сообщения
- Красный текст: ошибки и предупреждения

## Безопасность
- Скрипт требует настроенный доступ к кластеру Kubernetes
- Используйте RBAC для ограничения прав в кластере
- Проверяйте содержимое values файлов перед деплоем