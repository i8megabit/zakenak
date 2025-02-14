# GitOps Repository

## Версия
1.1.8

## Описание
Монорепозиторий для управления Kubernetes-инфраструктурой и приложениями.

## Обновления
- Добавлена поддержка NVIDIA GPU в кластере
- Настроен NVIDIA Device Plugin
- Добавлены скрипты для управления GPU ресурсами
- Обновлена документация по работе с GPU

## Настройка GPU
1. Убедитесь, что NVIDIA драйверы установлены на узлах
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

