# Исправление установки Kubernetes Dashboard

## Проблема

При попытке установить Kubernetes Dashboard вы можете столкнуться со следующей ошибкой:

```
Error: INSTALLATION FAILED: 1 error occurred:
        * Internal error occurred: failed calling webhook "validate.nginx.ingress.kubernetes.io": failed to call webhook: Post "https://ingress-nginx-controller-admission.ingress-nginx.svc:443/networking/v1/ingresses?timeout=10s": dial tcp 10.96.189.165:443: connect: connection refused
```

Эта ошибка возникает из-за того, что admission webhook ingress-nginx не отвечает при попытке валидации ресурса Ingress, созданного чартом Kubernetes Dashboard.

## Решение

Мы реализовали два решения для исправления этой проблемы:

### 1. Автоматическое исправление в процессе установки

Скрипт `charts.sh` был обновлен для автоматического отключения admission webhook ingress-nginx перед установкой Kubernetes Dashboard и повторного включения после завершения установки. Это должно предотвратить возникновение ошибки при обычной установке.

### 2. Скрипт ручного исправления

Если вы все еще сталкиваетесь с ошибкой, вы можете использовать предоставленный скрипт исправления:

```bash
./fix-dashboard-install.sh
```

Этот скрипт выполнит следующие действия:
1. Удалит существующий namespace kubernetes-dashboard
2. Отключит admission webhook ingress-nginx
3. Создаст новый namespace kubernetes-dashboard
4. Создаст необходимые ServiceAccount и ClusterRoleBinding
5. Установит чарт Kubernetes Dashboard
6. Повторно включит admission webhook ingress-nginx
7. Сгенерирует токен для доступа к дашборду

## Технические детали

Проблема возникает из-за того, что admission webhook ingress-nginx вызывается для валидации ресурса Ingress, созданного чартом Kubernetes Dashboard, но webhook не отвечает. Это может происходить по нескольким причинам:

1. Сервис webhook еще не готов
2. Существует проблема с сетью, препятствующая связи с webhook
3. Конфигурация webhook некорректна

Наше решение временно отключает валидацию webhook во время установки дашборда, что позволяет создать ресурс Ingress без валидации. После завершения установки мы повторно включаем webhook для будущих ресурсов Ingress.

## Дополнительная информация

Если вам нужно вручную отключить или включить admission webhook ingress-nginx, вы можете использовать следующие команды:

### Отключение webhook:

```bash
kubectl get validatingwebhookconfiguration ingress-nginx-admission -o yaml > /tmp/ingress-webhook-backup.yaml
kubectl delete validatingwebhookconfiguration ingress-nginx-admission
```

### Повторное включение webhook:

```bash
kubectl apply -f /tmp/ingress-webhook-backup.yaml
```

Или перезапустите контроллер ingress-nginx:

```bash
kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx
```