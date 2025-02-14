# GitOps Repository

## Версия
1.2.3

## Описание
Монорепозиторий для управления Kubernetes-инфраструктурой и приложениями.

## Обновления
- Добавлена автоматическая переустановка кластера при деплое
- Улучшена последовательность развертывания компонентов
- Добавлены проверки готовности на каждом этапе
- Оптимизирован процесс развертывания

## Использование
### Полное развертывание с пересозданием кластера:
```bash
./tools/k8s-kind-setup/deploy-all.sh
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

