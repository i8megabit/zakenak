# Open WebUI Helm Chart

## Версия
1.0.2

## Описание
Helm чарт для развертывания Open WebUI в Kubernetes кластере.

## Последние изменения
- Добавлен Service для маршрутизации трафика
- Настроена интеграция с Ingress-контроллером
- Исправлена проблема с endpoints

## Использование
```bash
./tools/helm-deployer/deploy-chart.sh -e prod -c ./helm-charts/open-webui/
```

## Конфигурация
Для настройки используйте values.yaml файл в корне чарта.

### Важные параметры
- service.port: Порт сервиса
- service.targetPort: Целевой порт контейнера
- release.namespace: Namespace для развертывания