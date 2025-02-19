# Setup Ingress

## Версия
1.0.0

## Описание
Инструмент для автоматизированной установки и настройки NGINX Ingress Controller в Kubernetes кластере. Обеспечивает корректную маршрутизацию трафика и интеграцию с cert-manager для управления TLS-сертификатами.

## Требования
- Kubernetes кластер 1.25+
- Helm 3.x
- kubectl настроенный для доступа к кластеру
- cert-manager (опционально, для автоматического управления TLS)

## Установка
```bash
./setup-ingress.sh
```

## Опции конфигурации
- `INGRESS_NAMESPACE`: Namespace для установки ingress-controller (по умолчанию: ingress-nginx)
- `INGRESS_CLASS_NAME`: Имя класса ingress (по умолчанию: nginx)
- `ENABLE_TLS`: Включить поддержку TLS (по умолчанию: true)

## Примеры использования
1. Стандартная установка:
```bash
./setup-ingress.sh
```

2. Установка с кастомным namespace:
```bash
INGRESS_NAMESPACE=custom-ingress ./setup-ingress.sh
```

## Проверка установки
```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```