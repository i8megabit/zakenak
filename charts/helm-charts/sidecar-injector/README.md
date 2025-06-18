# Sidecar Injector Helm Chart
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
Helm чарт для автоматической инжекции TLS сайдкаров в поды Kubernetes. Обеспечивает безопасную коммуникацию между сервисами через автоматическое внедрение TLS-прокси.

## Особенности
- Автоматическая инжекция TLS сайдкаров для входящего и исходящего трафика
- Интеграция с cert-manager для автоматического управления сертификатами
- Гибкая настройка конфигурации Nginx для каждого сайдкара
- Поддержка различных стратегий маршрутизации трафика
- Минимальное влияние на производительность (25m CPU, 32Mi RAM на сайдкар)

## Требования
- Kubernetes 1.19+
- Helm 3.0+
- cert-manager v1.0.0+
- Включенный RBAC в кластере

## Быстрый старт
1. Установка чарта:
```bash
helm install sidecar-injector ./helm-charts/sidecar-injector \
    --namespace prod \
    --create-namespace \
    --values values.yaml
```

2. Проверка установки:
```bash
kubectl get pods -n prod -l app=sidecar-injector
kubectl get svc -n prod -l app=sidecar-injector
```

## Конфигурация
### Основные параметры
| Параметр | Описание | По умолчанию |
|----------|-----------|--------------|
| `sidecar.ingressSidecar.enabled` | Включение входящего сайдкара | `true` |
| `sidecar.egressSidecar.enabled` | Включение исходящего сайдкара | `true` |
| `certManager.enabled` | Использование cert-manager | `true` |
| `certManager.issuerRef.name` | Имя ClusterIssuer | `local-ca-issuer` |

### Пример values.yaml
```yaml
sidecar:
  ingressSidecar:
    enabled: true
    port: 8443
    config: |
      server {
        listen 8443 ssl;
        ssl_certificate /etc/tls/tls.crt;
        ssl_certificate_key /etc/tls/tls.key;
        location / {
          proxy_pass http://localhost:8080;
        }
      }

  egressSidecar:
    enabled: true
    port: 8444
    config: |
      server {
        listen 8444;
        location / {
          proxy_pass https://backend.service:443;
          proxy_ssl_certificate /etc/tls/tls.crt;
          proxy_ssl_certificate_key /etc/tls/tls.key;
        }
      }
```

## Использование
### Добавление сайдкаров к подам
1. Добавьте аннотацию к поду:
```yaml
annotations:
  sidecar-injector.kubernetes.io/inject: "true"
```

2. Настройте конфигурацию сайдкара через ConfigMap:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-app-sidecar-config
data:
  nginx.conf: |
    server {
      listen 8443 ssl;
      ssl_certificate /etc/tls/tls.crt;
      ssl_certificate_key /etc/tls/tls.key;
      location / {
        proxy_pass http://localhost:8080;
      }
    }
```

## Мониторинг
### Проверка статуса сайдкаров
```bash
# Просмотр логов входящего сайдкара
kubectl logs -n prod -l app=sidecar-injector -c ingress-sidecar

# Просмотр логов исходящего сайдкара
kubectl logs -n prod -l app=sidecar-injector -c egress-sidecar

# Проверка сертификатов
kubectl get certificates -n prod
kubectl get secrets -n prod -l app=sidecar-injector
```

## Устранение неполадок
### Частые проблемы
1. Сайдкары не инжектируются:
   - Проверьте аннотации пода
   - Убедитесь, что webhook работает: `kubectl get validatingwebhookconfigurations`
   - Проверьте логи webhook: `kubectl logs -n prod -l app=sidecar-injector`

2. Проблемы с сертификатами:
   - Проверьте статус сертификата: `kubectl describe certificate -n prod`
   - Убедитесь, что cert-manager работает: `kubectl get pods -n cert-manager`
   - Проверьте секреты: `kubectl get secrets -n prod | grep tls`

### Команды отладки
```bash
# Проверка конфигурации Nginx
kubectl exec -it -n prod \
  $(kubectl get pods -n prod -l app=sidecar-injector -o name) \
  -c ingress-sidecar -- nginx -t

# Проверка TLS соединения
kubectl exec -it -n prod \
  $(kubectl get pods -n prod -l app=sidecar-injector -o name) \
  -- openssl s_client -connect localhost:8443
```

## Безопасность
- Все сертификаты автоматически обновляются за 15 дней до истечения
- Поддержка mTLS для взаимной аутентификации сервисов
- Изоляция сетевого трафика через NetworkPolicies
- Принцип наименьших привилегий в RBAC конфигурации

## Производительность
- Минимальное потребление ресурсов:
  - CPU: 25m (запрос) / 50m (лимит)
  - Memory: 32Mi (запрос) / 64Mi (лимит)
- Оптимизированная конфигурация Nginx
- Эффективное управление соединениями

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

## Поддержка
При возникновении проблем:
1. Проверьте [секцию устранения неполадок](#устранение-неполадок)
2. Создайте issue в репозитории
3. Приложите логи и описание проблемы

```plain text
Copyright (c) 2023-2025 Mikhail Eberil (@eberil)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```