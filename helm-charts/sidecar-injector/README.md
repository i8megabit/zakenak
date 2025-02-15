# Sidecar Injector Helm Chart

## Версия
0.1.0

## Описание
Helm чарт для автоматической инжекции TLS сайдкаров в поды Kubernetes. Обеспечивает безопасную коммуникацию между сервисами через автоматическое внедрение TLS-прокси.

## Особенности
- Автоматическая инжекция TLS сайдкаров
- Поддержка входящего и исходящего трафика
- Интеграция с cert-manager
- Настраиваемые конфигурации Nginx
- Автоматическое обновление сертификатов

## Требования
- Kubernetes 1.19+
- Helm 3.0+
- cert-manager
- RBAC enabled

## Установка
```bash
helm install sidecar-injector ./helm-charts/sidecar-injector \
	--namespace prod \
	--create-namespace \
	--values values.yaml
```

## Конфигурация
### Основные параметры
| Параметр | Описание | По умолчанию |
|----------|-----------|--------------|
| `sidecar.ingressSidecar.enabled` | Включение входящего сайдкара | `true` |
| `sidecar.egressSidecar.enabled` | Включение исходящего сайдкара | `true` |

### Настройки TLS
| Параметр | Описание | По умолчанию |
|----------|-----------|--------------|
| `certManager.enabled` | Использование cert-manager | `true` |
| `certManager.issuerRef.name` | Имя ClusterIssuer | `local-ca-issuer` |

## Архитектура
Чарт создает следующие компоненты:
1. Deployment с основным контейнером и сайдкарами
2. Service для доступа к сайдкарам
3. ConfigMap с конфигурацией Nginx
4. Certificate ресурс для TLS сертификатов
5. ServiceAccount и RBAC роли

## Безопасность
- Автоматическая генерация и ротация сертификатов
- Изоляция сетевого трафика
- Принцип наименьших привилегий для RBAC

## Мониторинг
### Проверка статуса сайдкаров
```bash
kubectl get pods -n prod -l app=sidecar-injector
```

### Проверка сертификатов
```bash
kubectl get certificates -n prod
kubectl get secrets -n prod -l app=sidecar-injector
```

## Устранение неполадок
### Проверка логов
```bash
# Логи входящего сайдкара
kubectl logs -n prod -l app=sidecar-injector -c ingress-sidecar

# Логи исходящего сайдкара
kubectl logs -n prod -l app=sidecar-injector -c egress-sidecar
```

### Проверка конфигурации
```bash
kubectl get configmap -n prod -l app=sidecar-injector
```

## Обновление
```bash
helm upgrade sidecar-injector ./helm-charts/sidecar-injector \
	--namespace prod \
	--values values.yaml
```

## Удаление
```bash
helm uninstall sidecar-injector -n prod
```