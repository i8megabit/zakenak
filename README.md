# GitOps Repository

## Версия
1.3.1

## Описание
Монорепозиторий для управления Kubernetes-инфраструктурой и приложениями.

## Обновления
- Оптимизирована поддержка NVIDIA GPU в WSL2
- Добавлена поддержка nvidia-smi из WSL2
- Обновлены пути монтирования для GPU
- Улучшена конфигурация NVIDIA Container Toolkit

## Использование
### Требования к системе
- NVIDIA GPU с поддержкой CUDA
- WSL2 с установленным NVIDIA Driver (версия 535 или выше)
- CUDA Toolkit 12.8
- Docker с поддержкой NVIDIA Container Runtime

### Подготовка WSL2 для работы с GPU
1. Убедитесь, что WSL2 использует правильный путь к nvidia-smi:
```bash
export PATH="/usr/lib/wsl/lib:$PATH"
which nvidia-smi

Убедитесь, что Docker настроен для работы с NVIDIA:

docker run --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi

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