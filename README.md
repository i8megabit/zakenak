# GitOps Repository

## Версия
1.0.4

## Описание
Монорепозиторий для управления Kubernetes-инфраструктурой и приложениями.

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

