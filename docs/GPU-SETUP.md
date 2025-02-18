# Настройка GPU для Zakenak

```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

Should Harbour?	No.
```

## Системные требования

### Hardware
- NVIDIA GPU (Compute Capability 7.0+)
- Минимум 16GB RAM (рекомендуется 32GB)
- Минимум 8GB GPU VRAM
- PCIe x16 слот (Gen3 или выше)
- NVMe SSD storage
- 10Gbps сеть (рекомендуется)
- Redundant Power Supply

### Software
- Windows 11 Pro/Enterprise
- WSL2 с Ubuntu 22.04 LTS
- NVIDIA Driver 535.104.05+
- CUDA Toolkit 12.8
- Docker Desktop с WSL2 бэкендом
- Kubernetes 1.25+
- Helm 3.x

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
memory=16GB
processors=4
swap=8GB
localhostForwarding=true
kernelCommandLine=systemd=true
EOF

# Применение настроек
wsl --shutdown
wsl --start
```

### 2. Установка драйверов NVIDIA

#### Windows
1. Скачайте последнюю версию [NVIDIA Driver](https://www.nvidia.com/download/index.aspx)
2. Выберите опции установки:
   - [x] Выполнить чистую установку
   - [x] Включить поддержку NVIDIA CUDA
   - [x] Включить поддержку WSL2
3. Перезагрузите систему
4. Проверьте установку:
```powershell
nvidia-smi
wsl --version
```

#### WSL2 Ubuntu
```bash
# Добавление CUDA репозитория
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin
sudo mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda-repo-wsl-ubuntu-12-8-local_12.8.0-1_amd64.deb
sudo dpkg -i cuda-repo-wsl-ubuntu-12-8-local_12.8.0-1_amd64.deb
sudo cp /var/cuda-repo-wsl-ubuntu-12-8-local/cuda-*-keyring.gpg /usr/share/keyrings/

# Установка CUDA
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-8

# Проверка установки
nvidia-smi
nvcc --version

# Добавление переменных окружения
echo 'export PATH=/usr/local/cuda-12.8/bin${PATH:+:${PATH}}' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc
source ~/.bashrc
```

## Настройка Docker

### 1. NVIDIA Container Toolkit
```bash
# Установка репозитория
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Установка toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Проверка установки
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi
```

### 2. Docker Desktop настройки
1. Откройте Docker Desktop Settings
2. Перейдите в WSL Integration
3. Включите Ubuntu-22.04
4. В Advanced Settings установите:
   - Memory: 8GB
   - Swap: 4GB
   - CPU: 4
5. В Features:
   - Enable WSL2 based engine
   - Enable NVIDIA GPU support

## Настройка Kubernetes

### 1. Создание Kind кластера
```bash
# Создание конфигурации
cat << EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true,nvidia.com/gpu=present"
  extraMounts:
  - hostPath: /usr/lib/wsl/lib
    containerPath: /usr/lib/wsl/lib
  - hostPath: /usr/local/cuda-12.8
    containerPath: /usr/local/cuda-12.8
  - hostPath: /usr/local/cuda
    containerPath: /usr/local/cuda
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
  - containerPort: 443
    hostPort: 443
EOF

# Создание кластера
kind create cluster --config kind-config.yaml
```

### 2. NVIDIA Device Plugin
```bash
# Установка NVIDIA Device Plugin
kubectl apply -f helm-charts/ollama/templates/nvidia-device-plugin.yaml

# Проверка статуса
kubectl -n kube-system get pods -l app=nvidia-device-plugin-daemonset
```

## Оптимизация производительности

### 1. Настройка GPU параметров
```yaml
# values-gpu.yaml
deployment:
  resources:
    limits:
      nvidia.com/gpu: "1"
      memory: "16Gi"
      cpu: "4"
    requests:
      nvidia.com/gpu: "1"
      memory: "8Gi"
      cpu: "2"
  env:
    - name: NVIDIA_VISIBLE_DEVICES
      value: "all"
    - name: NVIDIA_DRIVER_CAPABILITIES
      value: "compute,utility"
    - name: CUDA_CACHE_PATH
      value: "/tmp/cuda-cache"
    - name: OLLAMA_GPU_LAYERS
      value: "43"
    - name: OLLAMA_F16
      value: "true"
```

### 2. Мониторинг GPU
```bash
# Базовый мониторинг
watch -n 1 nvidia-smi

# Детальная статистика
nvidia-smi dmon -s pucvmet

# Мониторинг памяти
nvidia-smi --query-gpu=memory.used,memory.total,temperature.gpu,utilization.gpu --format=csv -l 1

# Профилирование
nvidia-smi pmon -s um
```

## Устранение неполадок

### 1. GPU не определяется в WSL2
```bash
# Проверка WSL2
wsl --status
wsl --update

# Проверка драйверов
nvidia-smi
nvidia-container-cli info

# Перезапуск WSL2
wsl --shutdown
wsl
```

### 2. Проблемы с CUDA
```bash
# Проверка путей
echo $LD_LIBRARY_PATH
echo $PATH

# Проверка библиотек
ldconfig -p | grep cuda
ls -l /usr/local/cuda/lib64/

# Проверка версии
nvcc --version
nvidia-smi
```

### 3. Проблемы с Docker
```bash
# Проверка runtime
docker info | grep -i runtime

# Проверка GPU
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi

# Проверка логов
docker logs ollama
```

### 4. Проблемы с Kubernetes
```bash
# Проверка статуса GPU в кластере
kubectl describe node | grep nvidia.com/gpu

# Проверка подов
kubectl get pods -n prod -l app=ollama -o yaml | grep nvidia.com/gpu

# Логи Device Plugin
kubectl logs -f -n kube-system -l k8s-app=nvidia-device-plugin
```

## Полезные команды

### GPU управление
```bash
# Очистка GPU памяти
sudo nvidia-smi --gpu-reset

# Установка режима производительности
sudo nvidia-smi --persistence-mode=1
sudo nvidia-smi --applications-clocks=5001,1590

# Мониторинг температуры
nvidia-smi -q -d TEMPERATURE
```

### Kubernetes
```bash
# Проверка доступности GPU
kubectl get nodes -o custom-columns=NAME:.metadata.name,GPU:.status.allocatable.\'nvidia\.com/gpu\'

# Проверка использования
kubectl describe pod -n prod -l app=ollama

# Проверка метрик
kubectl top pod -n prod
```

## Ссылки

- [NVIDIA CUDA WSL-Ubuntu Installation Guide](https://docs.nvidia.com/cuda/wsl-user-guide/index.html)
- [NVIDIA Container Toolkit Documentation](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
- [Kubernetes Device Plugin Documentation](https://github.com/NVIDIA/k8s-device-plugin)
- [Ollama GPU Documentation](https://github.com/ollama/ollama/blob/main/docs/gpu.md)
- [WSL2 GPU Support Documentation](https://learn.microsoft.com/en-us/windows/wsl/gpu)

```plain text
Copyright (c) 2023-2025 Mikhail Eberil (@eberil)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```