# Setup Cert Manager

## Версия
1.0.0

## Описание
Инструмент для автоматизированной установки и настройки cert-manager в Kubernetes кластере. Обеспечивает управление TLS-сертификатами и интеграцию с различными провайдерами сертификатов.

## Требования
- Kubernetes кластер 1.25+
- Helm 3.x
- kubectl настроенный для доступа к кластеру

## Установка
```bash
./setup-cert-manager.sh
```

## Функциональность
- Автоматическая установка cert-manager
- Настройка ClusterIssuer для самоподписанных сертификатов
- Интеграция с Kubernetes Ingress
- Автоматическое обновление сертификатов

## Проверка установки
```bash
kubectl get pods -n cert-manager
kubectl get clusterissuers
```