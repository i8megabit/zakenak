# Deploy All Tool

## Версия
1.3.0

## Описание
Инструмент для автоматизированного развертывания Kubernetes кластера в WSL2 с поддержкой GPU. Выполняет:

### Проверки конфигурации
- Валидация конфигурации Kubernetes и прав доступа
- Проверка GPU в WSL2:
  - Наличие nvidia-smi
  - Версия драйвера (535.104.05+)
  - Установка CUDA 12.8+
  - Настройка NVIDIA Container Toolkit
- Проверка GPU ресурсов в кластере:
  - Наличие узлов с GPU
  - Работа NVIDIA device plugin
  - Доступность GPU ресурсов
  - Тестовый запуск пода с GPU
- Проверка тензорных операций:
  - Поддержка CUDA в PyTorch
  - Тестирование GPU вычислений
  - Проверка производительности

### Установка компонентов
- Базовые компоненты:
  - Ingress NGINX Controller
  - Cert Manager
  - Local CA
  - CoreDNS
- Приложения:
  - Ollama с GPU поддержкой
  - Open WebUI
  - Kubernetes Dashboard

## Требования
- WSL2 (Ubuntu 22.04 LTS)
- NVIDIA GPU (RTX 4080 или выше)
- NVIDIA Driver 535.104.05+
- CUDA Toolkit 12.8+
- Docker Desktop с WSL2 интеграцией
- NVIDIA Container Toolkit
- Kind v0.20.0+
- Helm 3.0+

## Использование

### Параметры командной строки
```bash
./src/deploy-all.sh [опции]

Опции:
  --check-only     Только проверка конфигурации и GPU
  --reinstall-core Переустановка базовых компонентов
  --help          Показать справку
```

### Примеры использования
```bash
# Только проверка конфигурации
./src/deploy-all.sh --check-only

# Переустановка базовых компонентов
./src/deploy-all.sh --reinstall-core

# Полное развертывание
./src/deploy-all.sh
```

### Проверка GPU
```bash
# В WSL2
nvidia-smi
nvcc --version
docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu22.04 nvidia-smi

# В кластере
kubectl get nodes -l nvidia.com/gpu=true
kubectl get pods -n kube-system -l k8s-app=nvidia-device-plugin-daemonset

# Проверка тензоров
kubectl run tensor-test --rm -it --image=nvcr.io/nvidia/pytorch:23.12-py3 \
  --command -- python3 -c "import torch; print(torch.cuda.is_available())"
```

### Проверка компонентов
```bash
# Статус базовых компонентов
kubectl get pods -n ingress-nginx
kubectl get pods -n cert-manager
kubectl get pods -n kube-system

# Статус приложений
kubectl get pods -n prod
```

## Устранение неполадок

### GPU проблемы
1. Проверьте драйвер NVIDIA:
```bash
nvidia-smi
```

2. Проверьте NVIDIA Container Toolkit:
```bash
docker run --rm --gpus all nvidia/cuda:12.6.1-base-ubuntu22.04 nvidia-smi
```

4. Проверьте тензорные операции:
```bash
kubectl run tensor-test --rm -it \
  --image=nvcr.io/nvidia/pytorch:23.12-py3 \
  --command -- python3 -c \
  "import torch; print(torch.cuda.is_available()); print(torch.cuda.get_device_name(0))"
```

### Проблемы с CPU-only режимом
1. Убедитесь, что переменная окружения установлена:
```bash
export GPU_ENABLED=false
```

2. Запустите скрипт с параметрами:
```bash
./src/deploy-all.sh --skip-gpu-check --skip-tensor-check
```

3. Если под зависает при проверке тензоров:
```bash
# Принудительное удаление зависшего пода
kubectl delete pod tensor-test --force --grace-period=0
# Перезапуск с пропуском проверки тензоров
./src/deploy-all.sh --skip-tensor-check
```

### Kubernetes проблемы
1. Проверьте доступ к API:
```bash
kubectl cluster-info
```

2. Проверьте права:
```bash
kubectl auth can-i create deployments
```

3. Проверьте GPU ресурсы:
```bash
kubectl describe node | grep nvidia.com/gpu
```

### Проблемы с базовыми компонентами
1. Проверьте статус:
```bash
kubectl get pods --all-namespaces
```

2. Проверьте логи:
```bash
kubectl logs -n <namespace> <pod-name>
```

3. Переустановите компоненты:
```bash
./src/deploy-all.sh --reinstall-core
```