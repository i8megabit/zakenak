# Kind Kubernetes Cluster Setup

## Версия 1.1.0

### Использование

Для первоначальной установки:
```bash
./setup-kind.sh
```
Для восстановления после перезагрузки:

Доступ к Dashboard
Dashboard доступен двумя способами:

Напрямую через NodePort: https://localhost:30443
Через kubectl proxy: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
Решение проблем
Если кластер не работает после перезагрузки:

Запустите скрипт с параметром restore
Дождитесь завершения процесса восстановления