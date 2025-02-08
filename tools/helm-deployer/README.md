# Helm Chart Deployer

Версия: 1.1.0

Универсальный инструмент для деплоя Helm чартов в Kubernetes.

## Описание
Скрипт автоматизирует процесс деплоя Helm чартов с поддержкой различных конфигураций и окружений.

## Иерархия Values файлов
Скрипт поддерживает следующую иерархию values файлов (в порядке возрастания приоритета):

1. Глобальный values.yaml в корне helm-charts/
2. Values.yaml конкретного чарта
3. Кастомный values файл, указанный через параметр -f

Это позволяет:
- Определять общие настройки на уровне проекта
- Переопределять их на уровне чарта
- При необходимости, переопределять настройки для конкретного деплоя

## Возможности
- Деплой любого Helm чарта
- Поддержка кастомных values файлов
- Валидация чарта перед деплоем
- Поддержка dry-run режима
- Автоматическое создание namespace
- Подробный вывод для отладки

## Требования
- Kubernetes кластер
- Helm 3.x
- kubectl
- bash

## Использование

### Базовый деплой
```bash
./deploy-chart.sh -c ./charts/my-chart -r my-release
```

### Деплой с кастомными values
```bash
./deploy-chart.sh -c ./charts/my-chart -r my-release -f values.yaml
```

### Деплой в определенный namespace
```bash
./deploy-chart.sh -c ./charts/my-chart -r my-release -n my-namespace
```

### Пробный запуск (dry-run)
```bash
./deploy-chart.sh -c ./charts/my-chart -r my-release --dry-run
```

### Отладочный режим
```bash
./deploy-chart.sh -c ./charts/my-chart -r my-release --debug
```

## Параметры
- `-c, --chart CHART_PATH` - Путь к чарту (обязательно)
- `-r, --release NAME` - Имя релиза (обязательно)
- `-n, --namespace NAME` - Namespace (по умолчанию: default)
- `-f, --values FILE` - Путь к values файлу
- `--dry-run` - Выполнить пробный запуск
- `--debug` - Включить отладочный вывод
- `-h, --help` - Показать справку

## Примеры использования

### Деплой cert-manager
```bash
./deploy-chart.sh -c ./helm-charts/cert-manager -r cert-manager -n cert-manager
```

### Деплой sidecar-injector с кастомными values
```bash
./deploy-chart.sh -c ./helm-charts/sidecar-injector -r sidecar -n default -f custom-values.yaml
```