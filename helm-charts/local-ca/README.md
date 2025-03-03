# Local CA Helm Chart
```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

Should Harbour?	No.
```
## Версия
0.1.0

## Описание
Helm чарт для создания и управления локальным центром сертификации (CA) в Kubernetes кластере. Обеспечивает автоматическую генерацию и управление TLS сертификатами для внутренних сервисов.

## Особенности
- Автоматическое создание корневого CA
- Генерация TLS сертификатов для сервисов
- Интеграция с cert-manager
- Автоматическое обновление сертификатов
- Поддержка множественных DNS имен

## Требования
- Kubernetes 1.19+
- Helm 3.0+
- cert-manager v1.0.0+
- Настроенный RBAC

## Быстрый старт
```bash
helm install local-ca ./helm-charts/local-ca \
    --namespace prod \
    --create-namespace \
    --values values.yaml
```

## Конфигурация
### Основные параметры
| Параметр | Описание | По умолчанию |
|----------|-----------|--------------|
| `ca.commonName` | Имя корневого CA | `"Local CA"` |
| `ca.organization` | Организация | `"DevSecMLOps"` |
| `ca.validityDuration` | Срок действия CA | `"8760h"` |
| `ca.renewBefore` | Время до обновления | `"720h"` |

### Пример values.yaml
```yaml
ca:
  commonName: "Local CA"
  organization: "DevSecMLOps"
  validityDuration: "8760h"  # 1 год
  renewBefore: "720h"        # 30 дней
  secretName: "root-ca-key-pair"

certificates:
  - name: ollama-tls
    commonName: "ollama.prod.local"
    dnsNames:
      - "ollama.prod.local"
  - name: open-webui-tls
    commonName: "webui.prod.local"
    dnsNames:
      - "webui.prod.local"
```

## Использование
### Проверка установки
```bash
# Проверка статуса CA
kubectl get clusterissuer local-ca-issuer

# Проверка сертификатов
kubectl get certificates -n prod

# Проверка секретов
kubectl get secrets -n prod | grep tls
```

### Создание нового сертификата
1. Добавьте новый сертификат в values.yaml:
```yaml
certificates:
  - name: new-service-tls
    commonName: "service.prod.local"
    dnsNames:
      - "service.prod.local"
      - "service.prod.svc.cluster.local"
```

2. Обновите релиз:
```bash
helm upgrade local-ca ./helm-charts/local-ca \
    --namespace prod \
    --values values.yaml
```

## Безопасность
- Все приватные ключи хранятся в Kubernetes Secrets
- Автоматическая ротация сертификатов
- Ограниченный доступ через RBAC
- Изоляция в отдельном namespace

## Устранение неполадок
### Проверка статуса CA
```bash
kubectl describe clusterissuer local-ca-issuer
```

### Проверка сертификатов
```bash
kubectl describe certificate -n prod
```

### Проверка секретов
```bash
kubectl describe secret -n prod root-ca-key-pair
```

### Частые проблемы
1. Сертификат не создается:
   - Проверьте статус cert-manager: `kubectl get pods -n cert-manager`
   - Проверьте логи cert-manager: `kubectl logs -n cert-manager -l app=cert-manager`

2. Ошибки при обновлении:
   - Проверьте формат values.yaml
   - Убедитесь, что все required поля заполнены
   - Проверьте права доступа

## Обновление
```bash
helm upgrade local-ca ./helm-charts/local-ca \
    --namespace prod \
    --values values.yaml
```

## Удаление
```bash
helm uninstall local-ca -n prod
```

## Поддержка
При возникновении проблем:
1. Проверьте секцию "Устранение неполадок"
2. Создайте issue в репозитории
3. Приложите логи и описание проблемы

## Решение проблемы с доверием к сертификатам в браузере

При доступе к сервисам через HTTPS (например, `https://dashboard.prod.local`) браузер может показывать ошибку безопасности:

```
Ваше подключение не является закрытым
Злоумышленники могут пытаться украсть ваши данные (например, пароли, сообщения или номера кредитных карт) с dashboard.prod.local.
net::ERR_CERT_AUTHORITY_INVALID
```

Это происходит потому, что кластер использует самоподписанные сертификаты, которые не доверены браузером по умолчанию.

### Экспорт и установка корневого CA сертификата

Для решения этой проблемы необходимо экспортировать корневой CA сертификат и добавить его в доверенные сертификаты браузера:

```bash
# Экспорт корневого CA сертификата
./tools/k8s-kind-setup/setup-cert-manager/src/export-root-ca.sh
```

Скрипт экспортирует сертификат в `~/zakenak-certs/zakenak-root-ca.crt` и выводит инструкции по его установке в различных браузерах и операционных системах.

После установки сертификата в доверенные, браузер будет доверять всем сертификатам, выданным этим CA, и вы сможете безопасно открывать:
- https://dashboard.prod.local
- https://ollama.prod.local
- https://webui.prod.local