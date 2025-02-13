# Open WebUI Helm Chart

## Версия
1.0.1

## Описание
Helm чарт для развертывания Open WebUI в Kubernetes кластере.

## Последние изменения
- Исправлено форматирование YAML файлов
- Улучшена стабильность деплоя

## Использование
```bash
./tools/helm-deployer/deploy-chart.sh -e prod -c ./helm-charts/open-webui/
```

## Конфигурация
Для настройки используйте values.yaml файл в корне чарта.