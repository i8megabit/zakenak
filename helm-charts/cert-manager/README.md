# Cert Manager Helm Chart

## Версия
0.1.0

## Описание
Helm чарт для установки и настройки cert-manager с поддержкой локальных сертификатов.

## Особенности
- Автоматическая установка cert-manager
- Настройка локального CA
- Автоматическая генерация и обновление сертификатов
- Интеграция с Ingress-контроллером
- Поддержка самоподписанных сертификатов

## Требования
- Kubernetes 1.19+
- Helm 3.0+
- Ingress контроллер (опционально)

## Установка
```bash
helm install cert-manager ./helm-charts/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --values values.yaml
```

## Конфигурация
### Основные параметры
| Параметр | Описание | По умолчанию |
|----------|-----------|--------------|
| `installCRDs` | Установка CRDs | `true` |
| `replicaCount` | Количество реплик | `1` |

### ClusterIssuer
| Параметр | Описание | По умолчанию |
|----------|-----------|--------------|
| `clusterIssuer.enabled` | Включение ClusterIssuer | `true` |
| `clusterIssuer.name` | Имя ClusterIssuer | `selfsigned-issuer` |

## Использование
1. Установка чарта:
```bash
helm install cert-manager ./helm-charts/cert-manager
```

2. Проверка установки:
```bash
kubectl get pods -n cert-manager
kubectl get clusterissuers
```

3. Создание сертификата:
```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
    name: example-cert
    namespace: default
spec:
    secretName: example-cert-tls
    issuerRef:
        name: selfsigned-issuer
        kind: ClusterIssuer
    commonName: example.com
    dnsNames:
    - example.com
    - www.example.com
EOF
```

## Устранение неполадок
### Проверка статуса CRDs
```bash
kubectl get crds | grep cert-manager
```

### Проверка логов cert-manager
```bash
kubectl logs -n cert-manager -l app=cert-manager
```

### Проверка сертификатов
```bash
kubectl get certificates --all-namespaces
kubectl get certificaterequests --all-namespaces
```

## Безопасность
- Все сертификаты хранятся в Kubernetes Secrets
- Поддержка RBAC
- Изоляция в отдельном namespace