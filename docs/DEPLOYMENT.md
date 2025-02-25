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
- CUDA Toolkit 12.8
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

# Настройка лимитов памяти
cat << EOF > %UserProfile%\.wslconfig
[wsl2]
memory=40GB
processors=12
swap=16GB
localhostForwarding=true
kernelCommandLine=systemd.unified_cgroup_hierarchy=1
nestedVirtualization=true
guiApplications=true
debugConsole=false
[experimental]
hostAddressLoopback=true
bestEffortDnsParsing=true
EOF
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
wget https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda-repo-wsl-ubuntu-12-8-local_12.8.0-1_amd64.deb
sudo dpkg -i cuda-repo-wsl-ubuntu-12-8-local_12.8.0-1_amd64.deb
sudo cp /var/cuda-repo-wsl-ubuntu-12-8-local/cuda-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-8

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
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi
```

## Развертывание кластера

### 1. Автоматическое развертывание
```bash
# Полное развертывание с проверками
./tools/k8s-kind-setup/deploy-all/src/deploy-all.sh

# Только проверка конфигурации
./tools/k8s-kind-setup/deploy-all/src/deploy-all.sh --check-only

# Переустановка базовых компонентов
./tools/k8s-kind-setup/deploy-all/src/deploy-all.sh --reinstall-core
```

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

## Развертывание кластера

### 1. Создание Kind кластера
```bash
# Установка Kind
go install sigs.k8s.io/kind@latest

# Создание кластера с GPU поддержкой
kind create cluster --config helm-charts/kind-config.yaml

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
# Обновление всех компонентов
make deploy

# Обновление отдельного компонента
helm upgrade ollama ./helm-charts/ollama -n prod
```

### 2. Резервное копирование
```bash
# Бэкап etcd
kubectl exec -it -n kube-system etcd-control-plane -- \
    etcdctl snapshot save snapshot.db

# Бэкап конфигурации
kubectl get all --all-namespaces -o yaml > cluster-backup.yaml
```

### 3. Восстановление
```bash
# Восстановление из бэкапа
kubectl apply -f cluster-backup.yaml

# Откат релиза
helm rollback ollama 1 -n prod
```

## Устранение неполадок

### 1. Проблемы с GPU
- Проверка драйверов: `nvidia-smi`
- Проверка CUDA: `nvcc --version`
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

```plain text
Copyright (c) 2025 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. 
See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT.
```