# Руководство по развертыванию Zakenak

```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

Should Harbour?	No.
```

## Навигация
- [Главная страница](../README.md)
- Документация
  - [Руководство по развертыванию](DEPLOYMENT.md) (текущий документ)
  - [GitOps подход](GITOPS.md)
  - [API Reference](api.md)
  - [Устранение неполадок](troubleshooting.md)
  - [GPU в WSL2](GPU-WSL.md)
  - [Использование Docker](DOCKER-USAGE.md)
  - [Настройка KUBECONFIG](KUBECONFIG.md)
  - [Мониторинг](MONITORING.md)
  - [Настройка сети](NETWORK-CONFIGURATION.md)
  - [Миграция и настройка WSL и Docker](WSL-DOCKER-MIGRATION.md)
- [Примеры](../examples/README.md)

## Требования к системе

### Hardware
- NVIDIA GPU (Compute Capability 7.0+)
- 16GB RAM минимум
- NVMe SSD storage
- 10Gbps сеть (рекомендуется)
- Redundant Power Supply

### Software
- Windows 11 Pro или Enterprise
- WSL2 с Ubuntu 22.04 LTS
- Docker Desktop с WSL2 интеграцией
- NVIDIA драйвер версии 535.104.05 или выше
- CUDA Toolkit 12.6
- Kubernetes 1.25+
- Helm 3.x
- Go 1.21+

## Подготовка окружения

### 1. Настройка WSL2
```bash
# Включение WSL2
wsl --install
wsl --set-default-version 2
wsl --install -d Ubuntu-22.04

# Настройка WSL2 (выполнить в PowerShell на Windows)
# Создайте или отредактируйте файл .wslconfig
notepad "$env:USERPROFILE\.wslconfig"

# Добавьте следующие настройки в .wslconfig:
# [boot]
# systemd=true
# [wsl2]
# memory=24GB
# processors=8
# swap=8GB
# localhostForwarding=true
# kernelCommandLine=cgroup_no_v1=all cgroup_enable=memory swapaccount=1
# nestedVirtualization=true
# guiApplications=true
# debugConsole=false
# [experimental]
# hostAddressLoopback=true
# bestEffortDnsParsing=true
```

### 2. Установка CUDA
```bash
# Проверка наличия GPU
nvidia-smi

# Проверка версии драйвера
if ! nvidia-smi --query-gpu=driver_version --format=csv,noheader | grep -q "535.104.05"; then
    echo "Требуется обновить драйвер NVIDIA до версии 535.104.05 или выше"
    exit 1
fi

# Установка CUDA Toolkit
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin
sudo mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/12.6.0/local_installers/cuda-repo-wsl-ubuntu-12-6-local_12.6.0-1_amd64.deb
sudo dpkg -i cuda-repo-wsl-ubuntu-12-6-local_12.6.0-1_amd64.deb
sudo cp /var/cuda-repo-wsl-ubuntu-12-6-local/cuda-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-6

# Проверка установки
nvidia-smi
nvcc --version
```

### 3. Настройка NVIDIA Container Toolkit
```bash
# Настройка репозитория
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Установка NVIDIA Container Toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Настройка container runtime
sudo nvidia-ctk runtime configure --runtime=docker

# Проверка GPU в контейнере
docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu22.04 nvidia-smi
```

## Развертывание кластера

### 1. Автоматическое развертывание
Для полного автоматического развертывания кластера используйте скрипт [deploy-all.sh](../tools/k8s-kind-setup/deploy-all/src/deploy-all.sh):

```bash
# Полное развертывание с проверками и безопасным откатом
./tools/k8s-kind-setup/deploy-all/src/deploy-all.sh

# Только проверка конфигурации
./tools/k8s-kind-setup/deploy-all/src/deploy-all.sh --check-only

# Переустановка базовых компонентов
./tools/k8s-kind-setup/deploy-all/src/deploy-all.sh --reinstall-core

# Пропуск настройки WSL
./tools/k8s-kind-setup/deploy-all/src/deploy-all.sh --no-wsl

# Принудительное выполнение (игнорирование идемпотентности)
./tools/k8s-kind-setup/deploy-all/src/deploy-all.sh --force

# Запуск в CPU-only режиме (без GPU)
./tools/k8s-kind-setup/deploy-all/src/deploy-all.sh --skip-gpu-check
```

Скрипт выполняет следующие действия:
1. Проверяет конфигурацию системы и наличие необходимых компонентов
2. Настраивает WSL2 для работы с GPU (если не указан флаг --no-wsl)
3. Создает кластер KIND с поддержкой GPU
4. Устанавливает базовые компоненты (cert-manager, local-ca, ingress-nginx)
5. Настраивает DNS и TLS
6. Устанавливает AI сервисы (Ollama, Open WebUI)
7. Проводит валидацию развертывания

### 2. Проверка GPU в кластере
```bash
# Проверка узлов с GPU
kubectl get nodes -l nvidia.com/gpu=true
kubectl describe node -l nvidia.com/gpu=true | grep nvidia.com/gpu

# Проверка NVIDIA device plugin
kubectl get pods -n kube-system -l k8s-app=nvidia-device-plugin-daemonset

# Проверка тензорных операций
kubectl run tensor-test --rm -it --image=nvcr.io/nvidia/pytorch:23.12-py3 \
  --command -- python3 -c "import torch; print(torch.cuda.is_available())"
```

### 3. Установка NVIDIA Device Plugin с помощью Helm
```bash
# Установка NVIDIA Device Plugin
helm upgrade --install \
    nvidia-device-plugin ./helm-charts/nvidia-device-plugin \
    --namespace kube-system \
    --values ./helm-charts/nvidia-device-plugin/values.yaml

# Проверка статуса
kubectl get pods -n kube-system -l k8s-app=nvidia-device-plugin-daemonset
kubectl logs -n kube-system -l k8s-app=nvidia-device-plugin-daemonset
```

Для работы с потребительскими GPU (GeForce RTX серии) в WSL2, наша реализация NVIDIA Device Plugin включает:

1. Дополнительные точки монтирования для библиотек NVIDIA
2. Расширенные переменные окружения для конфигурации GPU
3. Явное указание команды и аргументов для совместимости с WSL2

Подробнее о настройке GPU в WSL2 см. [GPU в WSL2](GPU-WSL.md).

## Развертывание кластера

### 1. Создание Kind кластера
```bash
# Установка Kind
go install sigs.k8s.io/kind@latest

# Создание кластера с GPU поддержкой
kind create cluster --config tools/k8s-kind-setup/kind/config/kind-config-gpu.yml

# Проверка статуса
kubectl cluster-info
kubectl get nodes -o wide
```

### 2. Установка Core Services

#### Cert Manager
```bash
helm upgrade --install \
    cert-manager ./helm-charts/cert-manager \
    --namespace prod \
    --create-namespace \
    --set installCRDs=true \
    --values ./helm-charts/cert-manager/values.yaml
```

#### Local CA
```bash
helm upgrade --install \
    local-ca ./helm-charts/local-ca \
    --namespace prod \
    --values ./helm-charts/local-ca/values.yaml
```

#### Sidecar Injector
```bash
helm upgrade --install \
    sidecar-injector ./helm-charts/sidecar-injector \
    --namespace prod \
    --values ./helm-charts/sidecar-injector/values.yaml
```

### 3. Установка AI Services

#### Ollama
```bash
helm upgrade --install \
    ollama ./helm-charts/ollama \
    --namespace prod \
    --values ./helm-charts/ollama/values.yaml \
    --set gpu.enabled=true \
    --set resources.limits.nvidia.com/gpu=1
```

#### Open WebUI
```bash
helm upgrade --install \
    open-webui ./helm-charts/open-webui \
    --namespace prod \
    --values ./helm-charts/open-webui/values.yaml
```

## Проверка развертывания

### 1. Проверка Core Services
```bash
# Проверка сертификатов
kubectl get certificates -n prod
kubectl get certificaterequests -n prod
kubectl get secrets -n prod

# Проверка сайдкаров
kubectl get mutatingwebhookconfigurations
kubectl get pods -n prod -o jsonpath='{.items[*].spec.containers[*].name}'
```

### 2. Проверка AI Services
```bash
# Проверка Ollama
kubectl exec -it deployment/ollama -n prod -- nvidia-smi
kubectl logs -f deployment/ollama -n prod

# Проверка WebUI
kubectl port-forward svc/open-webui -n prod 8080:8080
curl http://localhost:8080/health
```

### 3. Проверка GPU
```bash
# Статус GPU
kubectl exec -it deployment/ollama -n prod -- nvidia-smi

# Мониторинг производительности
kubectl exec -it deployment/ollama -n prod -- nvidia-smi dmon -s pucvmet

# Проверка CUDA
kubectl exec -it deployment/ollama -n prod -- python3 -c "import torch; print(torch.cuda.is_available())"
```

Для более подробной информации об использовании Docker с GPU см. [Руководство по использованию Docker](DOCKER-USAGE.md).

## Настройка безопасности

### 1. Network Policies
```bash
kubectl apply -f ./helm-charts/network-policies/

# Проверка применения
kubectl get networkpolicies -n prod
```

### 2. RBAC
```bash
kubectl apply -f ./helm-charts/rbac/

# Проверка ролей
kubectl get roles,rolebindings -n prod
```

### 3. Pod Security
```bash
kubectl label namespace prod \
    pod-security.kubernetes.io/enforce=restricted

# Проверка меток
kubectl get namespace prod --show-labels
```

## Мониторинг

### 1. Логи
```bash
# Установка Loki
helm upgrade --install loki grafana/loki-stack \
    --namespace monitoring \
    --create-namespace

# Проверка логов
kubectl logs -f -l app=ollama -n prod
```

### 2. Метрики
```bash
# Установка Prometheus
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring

# Проверка метрик
kubectl port-forward svc/prometheus-operated -n monitoring 9090:9090
```

### 3. GPU мониторинг
```bash
# Установка DCGM экспортера
helm upgrade --install dcgm nvidia/dcgm-exporter \
    --namespace monitoring

# Проверка метрик GPU
kubectl exec -it -n monitoring dcgm-exporter-xxx -- curl localhost:9400/metrics
```

## Обновление и обслуживание

### 1. Обновление компонентов
```bash
# Безопасное обновление всех компонентов
./tools/k8s-kind-setup/deploy-all/src/deploy-all.sh --force

# Безопасное обновление отдельного компонента
./tools/k8s-kind-setup/charts/src/charts.sh upgrade ollama
```

### 2. Резервное копирование
```bash
# Автоматическое резервное копирование (выполняется перед каждой операцией)
# Резервные копии хранятся в директории /tools/k8s-kind-setup/.backup/

# Бэкап etcd
kubectl exec -it -n kube-system etcd-control-plane -- \
    etcdctl snapshot save snapshot.db

# Бэкап конфигурации
kubectl get all --all-namespaces -o yaml > cluster-backup.yaml
```

### 3. Восстановление
```bash
# Автоматическое восстановление при сбоях
./tools/k8s-kind-setup/deploy-all/src/deploy-all.sh --rollback

# Восстановление из бэкапа
kubectl apply -f cluster-backup.yaml

# Откат релиза
helm rollback ollama 1 -n prod
```

## Устранение неполадок

### 1. Проблемы с GPU
- Проверка драйверов: `nvidia-smi`
- Логи NVIDIA: `journalctl -u nvidia-persistenced`
- Device Plugin логи: `kubectl logs -n kube-system nvidia-device-plugin`

### 2. Проблемы с сертификатами
- Проверка cert-manager: `kubectl describe certificate -n prod`
- Проверка CA: `kubectl get secrets -n prod`
- Логи cert-manager: `kubectl logs -n cert-manager cert-manager`

### 3. Сетевые проблемы
- Проверка DNS: `kubectl exec -it busybox -- nslookup kubernetes.default`
- Проверка сервисов: `kubectl get endpoints -n prod`
- Проверка политик: `kubectl describe networkpolicy -n prod`

### 4. Проблемы с развертыванием
- Проверка состояния: `ls -la /tools/k8s-kind-setup/.state/`
- Просмотр истории развертывания: `cat /tools/k8s-kind-setup/.state/deploy_history.log`
- Восстановление из бэкапа: `./tools/k8s-kind-setup/deploy-all/src/deploy-all.sh --rollback`
- Очистка состояния: `./tools/k8s-kind-setup/deploy-all/src/deploy-all.sh --cleanup`

## Полезные скрипты и инструменты

Для упрощения процесса развертывания и управления кластером, в репозитории доступны следующие скрипты и инструменты:

### [deploy-all.sh](../tools/k8s-kind-setup/deploy-all/src/deploy-all.sh)
Комплексный скрипт для автоматического развертывания всего кластера:
- Интеллектуальное обнаружение и восстановление после ошибок
- Поддержка как GPU, так и CPU-only режимов
- Автоматическая установка всех необходимых компонентов
- Расширенная валидация и тестирование

### [charts.sh](../tools/k8s-kind-setup/charts/src/charts.sh)
Мощный инструмент для управления Helm чартами:
- Автоматическое разрешение зависимостей чартов
- Поддержка пользовательских values и конфигураций
- Интеллектуальное упорядочивание установки чартов
- Комплексная обработка ошибок

### [setup-dns.sh](../tools/k8s-kind-setup/setup-dns/src/setup-dns.sh)
Специализированный инструмент для настройки DNS в кластерах Kubernetes:
- Конфигурация CoreDNS для локального разрешения доменов
- Интеграция с Windows hosts для локальной разработки
- Поддержка пользовательских DNS конфигураций
- Автоматическая валидация настройки DNS

### [setup-ingress.sh](../tools/k8s-kind-setup/setup-ingress/src/setup-ingress.sh)
Инструмент для настройки Ingress контроллера:
- Автоматическая установка Nginx Ingress Controller
- Интеграция с cert-manager для TLS
- Настройка правил маршрутизации
- Проверка доступности сервисов

### [dashboard-token.sh](../tools/k8s-kind-setup/dashboard-token/src/dashboard-token.sh)
Утилита для генерации и управления токенами доступа к Kubernetes Dashboard:
- Безопасная генерация токенов
- Настройка RBAC
- Управление доступом
- Поддержка ротации токенов

### [connectivity-check.sh](../tools/k8s-kind-setup/connectivity-check/src/check-services.sh)
Комплексный инструмент для проверки связности:
- Проверка конечных точек сервисов
- Валидация сетевых политик
- Тестирование Ingress контроллера
- Проверка межнеймспейсной коммуникации

### [setup-cert-manager.sh](../tools/k8s-kind-setup/setup-cert-manager/src/setup-cert-manager.sh)
Инструмент для настройки управления сертификатами:
- Установка и настройка cert-manager
- Создание локального CA
- Настройка выпуска сертификатов
- Экспорт корневого CA для браузеров

```plain text
Copyright (c) 2025 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. 
See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT.
```