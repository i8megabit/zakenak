# GitOps Repository

## Версия
1.2.0

## Описание
Монорепозиторий для управления Kubernetes-инфраструктурой и приложениями.

## Обновления
- Настроена обязательная поддержка GPU для Ollama
- Оптимизированы параметры GPU для максимальной производительности
- Обновлены ресурсные лимиты для работы с GPU
- Добавлены nodeSelector и tolerations для GPU-узлов

## Настройка GPU
1. Убедитесь, что поды Ollama запущены:
```bash
kubectl get pods -n prod -l app=ollama
```
2. Запустите скрипт настройки GPU:
```bash
./tools/k8s-kind-setup/setup-gpu.sh
```
3. Проверьте статус GPU:
```bash
kubectl get nodes -o=custom-columns=NAME:.metadata.name,GPU:.metadata.labels.nvidia\\.com/gpu
```

## Настройка DNS
1. Запустите скрипт настройки DNS:
```bash
./tools/k8s-kind-setup/setup-dns.sh
```

2. Проверьте резолвинг доменов:
```bash
kubectl run -i --rm --restart=Never busybox --image=busybox:1.28 -- nslookup webui.prod.local
kubectl run -i --rm --restart=Never busybox --image=busybox:1.28 -- nslookup ollama.prod.local
```

## Структура репозитория
- /helm-charts - Helm чарты для приложений
- /tools
    - /k8s-kind-setup - Скрипты настройки кластера и DNS
    - /helm-deployer - Инструменты для деплоя

