# GitOps Repository

## Версия
1.2.1

## Описание
Монорепозиторий для управления Kubernetes-инфраструктурой и приложениями.

## Обновления
- Добавлен скрипт автоматического развертывания всех компонентов
- Реализована автоматическая настройка GPU для Ollama
- Улучшена последовательность установки компонентов
- Добавлены проверки успешности развертывания

## Использование
1. Запустите скрипт автоматического развертывания:
```bash
chmod +x ./tools/k8s-kind-setup/deploy-all.sh
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

