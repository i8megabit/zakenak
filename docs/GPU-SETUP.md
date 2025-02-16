# Настройка GPU для Ƶakenak™®

## Системные требования

### Hardware
- NVIDIA GPU с поддержкой CUDA (Compute Capability 7.0+)
- Минимум 8GB GPU RAM
- PCIe x16 слот

### Software
- Windows 11 с WSL2
- Ubuntu 22.04 LTS в WSL2
- NVIDIA Driver 535.104.05+
- CUDA Toolkit 12.8
- Docker Desktop с WSL2 backend
- Kubernetes 1.25+

## Установка драйверов NVIDIA

### Windows
1. Скачайте и установите последнюю версию [NVIDIA Driver](https://www.nvidia.com/download/index.aspx)
2. Включите поддержку GPU в WSL2:
   ```powershell
   wsl --update
   wsl --shutdown
   ```

### WSL2 Ubuntu
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
```

## Настройка Docker

### NVIDIA Container Toolkit
```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### Проверка установки Docker
```bash
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi
```

## Настройка Kubernetes (kind)

### Создание кластера
```bash
# Создание кластера с поддержкой GPU
kind create cluster --config helm-charts/kind-config.yaml
```

### Конфигурация kind
```yaml
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
  # WSL2 specific NVIDIA paths
  - hostPath: /usr/lib/wsl/lib
	containerPath: /usr/lib/wsl/lib
  # CUDA toolkit
  - hostPath: /usr/local/cuda-12.8
	containerPath: /usr/local/cuda-12.8
  - hostPath: /usr/local/cuda
	containerPath: /usr/local/cuda
```

### NVIDIA Device Plugin
```bash
# Установка NVIDIA Device Plugin
kubectl apply -f helm-charts/ollama/templates/nvidia-device-plugin.yaml
```

## Проверка установки

### CUDA
```bash
# Проверка CUDA
nvcc --version
nvidia-smi
```

### Kubernetes
```bash
# Проверка статуса GPU в кластере
kubectl describe node | grep nvidia.com/gpu
kubectl get pods -n prod -l app=ollama -o yaml | grep nvidia.com/gpu
```

## Оптимизация производительности

### Параметры Ollama
```yaml
deployment:
  resources:
	limits:
	  nvidia.com/gpu: "1"
	  memory: "16Gi"
	requests:
	  nvidia.com/gpu: "1"
	  memory: "8Gi"
  env:
	- name: OLLAMA_COMPUTE_TYPE
	  value: "gpu"
	- name: OLLAMA_GPU_LAYERS
	  value: "43"
	- name: OLLAMA_F16
	  value: "true"
```

### Мониторинг GPU
```bash
# Мониторинг использования GPU
watch -n 1 nvidia-smi

# Детальная статистика
nvidia-smi dmon -s pucvmet
```

## Troubleshooting

### Общие проблемы

1. GPU не определяется в WSL2
```bash
# Проверка статуса WSL2
wsl --status
# Перезапуск WSL2
wsl --shutdown
wsl
```

2. Ошибки CUDA
```bash
# Проверка переменных окружения
echo $LD_LIBRARY_PATH
echo $PATH
# Проверка библиотек
ldconfig -p | grep cuda
```

3. Проблемы с Docker
```bash
# Проверка runtime
docker info | grep -i runtime
# Проверка GPU
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi
```

### Логи и отладка

```bash
# Логи Ollama
kubectl logs -f deployment/ollama -n prod

# Логи NVIDIA Device Plugin
kubectl logs -f daemonset/nvidia-device-plugin-daemonset -n prod
```

## Полезные команды

### Управление GPU
```bash
# Очистка GPU памяти
sudo nvidia-smi --gpu-reset

# Профилирование
nvidia-smi pmon -s um

# Мониторинг температуры
nvidia-smi -q -d TEMPERATURE
```

### Kubernetes
```bash
# Проверка доступности GPU
kubectl get nodes -o custom-columns=NAME:.metadata.name,GPU:.status.allocatable.\'nvidia\.com/gpu\'

# Проверка использования GPU
kubectl describe pod -n prod -l app=ollama
```

## Ссылки

- [NVIDIA CUDA WSL-Ubuntu Installation Guide](https://docs.nvidia.com/cuda/wsl-user-guide/index.html)
- [NVIDIA Container Toolkit Documentation](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
- [Kubernetes Device Plugin Documentation](https://github.com/NVIDIA/k8s-device-plugin)
- [Ollama GPU Documentation](https://github.com/ollama/ollama/blob/main/docs/gpu.md)

/*
 * Copyright (c) 2024 Mikhail Eberil
 * 
 * This file is part of Zakenak project and is released under the terms of the
 * MIT License. See LICENSE file in the project root for full license 
 * information.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * 
 * See the MIT License for more details.
 * 
 * The name "Zakenak" and associated branding are trademarks of @eberil
 * and may not be used without express written permission.
 */