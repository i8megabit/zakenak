# GPU и тензорные операции в WSL2

## Навигация
- [Главная страница](../README.md)
- Документация
  - [Руководство по развертыванию](DEPLOYMENT.md)
  - [GitOps подход](GITOPS.md)
  - [API Reference](api.md)
  - [Устранение неполадок](troubleshooting.md)
  - [GPU в WSL2](GPU-WSL.md) (текущий документ)
  - [Использование Docker](DOCKER-USAGE.md)
  - [Настройка KUBECONFIG](KUBECONFIG.md)
  - [Мониторинг](MONITORING.md)
  - [Настройка сети](NETWORK-CONFIGURATION.md)
  - [Миграция и настройка WSL и Docker](WSL-DOCKER-MIGRATION.md)
- [Примеры](../examples/README.md)

## Содержание
1. [Проверка GPU в WSL2](#проверка-gpu-в-wsl2)
2. [Проверка CUDA](#проверка-cuda)
3. [Проверка тензорных операций](#проверка-тензорных-операций)
4. [Устранение неполадок](#устранение-неполадок)

## Проверка GPU в WSL2

Для проверки доступности GPU в WSL2 выполните следующие команды:

```bash
# Базовая проверка наличия GPU
nvidia-smi
```

Успешный вывод должен содержать информацию о вашей видеокарте, версии драйвера и CUDA:

```
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 560.35.02              Driver Version: 560.94       CUDA Version: 12.6     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  NVIDIA GeForce RTX 4080        On | 00000000:01:00.0 On |                  N/A |
|  0%   49C    P0             49W /  340W |    1440MiB /  16376MiB |      0%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
```

## Проверка CUDA

Для проверки установки CUDA выполните:

```bash
# Проверка наличия компилятора CUDA
nvcc --version
```

Успешный вывод должен содержать информацию о версии CUDA:

```
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2023 NVIDIA Corporation
Built on Fri_Nov__3_17:16:49_PDT_2023
Cuda compilation tools, release 12.6, V12.6.91
Build cuda_12.6.r12.6/compiler.33567101_0
```

Если команда `nvcc` не найдена, проверьте переменные окружения:

```bash
echo $PATH | grep cuda
echo $LD_LIBRARY_PATH | grep cuda
```

Если пути к CUDA отсутствуют, добавьте их в файл `.bashrc`:

```bash
echo 'export PATH=/usr/local/cuda-12.6/bin:${PATH}' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64:${LD_LIBRARY_PATH}' >> ~/.bashrc
source ~/.bashrc
```

## Проверка тензорных операций

### TensorFlow

Для проверки работы TensorFlow с GPU выполните:

```bash
# Проверка TensorFlow с GPU
docker run --rm --gpus all -it --shm-size=1g --ulimit memlock=-1 --ulimit stack=67108864 \
  nvcr.io/nvidia/tensorflow:23.11-tf2-py3 \
  python -c "import tensorflow as tf; print('Доступные GPU:', tf.config.list_physical_devices('GPU'))"
```

Успешный вывод должен содержать список доступных GPU устройств:

```
Доступные GPU: [PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')]
```

### PyTorch

Для проверки работы PyTorch с GPU выполните:

```bash
# Проверка PyTorch с GPU
docker run --rm --gpus all -it \
  nvcr.io/nvidia/pytorch:23.12-py3 \
  python -c "import torch; print('CUDA доступен:', torch.cuda.is_available()); print('Устройство GPU:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'Нет')"
```

Успешный вывод должен подтвердить доступность CUDA и показать название GPU устройства:

```
CUDA доступен: True
Устройство GPU: NVIDIA GeForce RTX 4080
```

## CPU-only режим

Zakenak поддерживает работу в режиме CPU-only, когда GPU недоступен или не требуется. В этом режиме:

1. Автоматически пропускаются проверки GPU и тензорных операций
2. Не устанавливается NVIDIA Device Plugin
3. Компоненты настраиваются для работы без GPU

Для активации CPU-only режима установите переменную окружения:

```bash
export GPU_ENABLED=false
```

Или используйте параметр `--skip-gpu-check` при запуске скрипта:

```bash
./tools/k8s-kind-setup/deploy-all/src/deploy-all.sh --skip-gpu-check
```

В CPU-only режиме:
- Проверка тензорных операций автоматически пропускается
- Ollama будет работать в режиме CPU (с ограниченной производительностью)
- Не будут выполняться тесты GPU ресурсов

Этот режим полезен для:
- Разработки и тестирования на системах без GPU
- Запуска в облачных средах без GPU-ускорения
- Экономии ресурсов при работе с небольшими моделями

## Настройка кластера KIND с GPU в WSL2

Для корректной работы кластера KIND с поддержкой GPU в WSL2 необходимо правильно настроить cgroup и Docker.

### Настройка cgroup в WSL2

1. В Windows PowerShell создайте или отредактируйте файл `.wslconfig`:

```bash
# В Windows PowerShell создайте или отредактируйте файл .wslconfig
notepad "$env:USERPROFILE\.wslconfig"
```

2. Добавьте следующие настройки в `.wslconfig`:

```
[boot]
systemd=true

[wsl2]
kernelCommandLine = cgroup_no_v1=all cgroup_enable=memory swapaccount=1
```

3. Настройте Docker daemon внутри WSL2 для работы с cgroup v2 и systemd:
   (Эти настройки применяются к Docker daemon внутри WSL2, а не к Docker Desktop)

```bash
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  }
}
EOF
```

4. Перезапустите Docker и WSL:

```bash
# Перезапуск Docker
sudo systemctl restart docker || sudo service docker restart

# В PowerShell на Windows
wsl --shutdown
```

### Создание кластера KIND с поддержкой GPU

После настройки cgroup и Docker, вы можете создать кластер KIND с поддержкой GPU:

```bash
# Создание кластера с конфигурацией для GPU
kind create cluster --config tools/k8s-kind-setup/kind/config/kind-config-gpu.yml --wait 15m
```

Конфигурация кластера должна включать:

1. Настройку cgroup-driver для kubelet
2. Монтирование необходимых библиотек NVIDIA
3. Настройку ресурсов для узлов

Пример конфигурации:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: "127.0.0.1"
  disableDefaultCNI: false
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
        feature-gates: "DevicePlugins=true"
        eviction-hard: "memory.available<100Mi"
        system-reserved: "memory=500Mi"
        cgroup-driver: "systemd"
  extraMounts:
  - hostPath: /usr/lib/wsl/lib
    containerPath: /usr/lib/wsl/lib
  - hostPath: /usr/bin/nvidia-smi
    containerPath: /usr/bin/nvidia-smi
  - hostPath: /usr/lib/x86_64-linux-gnu
    containerPath: /usr/lib/x86_64-linux-gnu
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
```

После создания кластера, установите NVIDIA Device Plugin:

```bash
# Создание namespace для NVIDIA
kubectl create namespace gpu-operator

# Установка NVIDIA Device Plugin
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.17.0/nvidia-device-plugin.yml

# Проверка статуса (DaemonSet будет установлен в namespace kube-system)
kubectl get pods -A -l k8s-app=nvidia-device-plugin-daemonset
```

Обратите внимание, что NVIDIA Device Plugin устанавливается в namespace `kube-system` по умолчанию, независимо от того, какой namespace был создан ранее.

### Использование пользовательского манифеста для NVIDIA Device Plugin

Для работы с потребительскими GPU (GeForce RTX серии) в WSL2 и Kubernetes, мы используем пользовательский манифест для NVIDIA Device Plugin, который:

1. Монтирует необходимые библиотеки NVIDIA с хоста в контейнер
2. Настроен на работу с GeForce RTX GPU вместо серверных Tesla GPU
3. Имеет параметр `FAIL_ON_INIT_ERROR: "false"`, который позволяет продолжить работу даже при некоторых ошибках инициализации

Этот манифест находится в репозитории по пути `tools/k8s-kind-setup/nvidia-device-plugin-custom.yml` и автоматически применяется скриптами настройки.

### Отличия от официального NVIDIA Device Plugin

Наша реализация NVIDIA Device Plugin имеет следующие отличия от официальной:

1. Дополнительные точки монтирования для библиотек NVIDIA в WSL2
2. Расширенные переменные окружения для конфигурации GPU
3. Явное указание команды и аргументов для совместимости с WSL2
4. Использование `privileged: true` в securityContext для доступа к устройствам GPU
5. Использование правильного пути к бинарному файлу (`/usr/bin/nvidia-device-plugin`)

Эти изменения необходимы для корректной работы с потребительскими GPU (GeForce RTX серии) в среде WSL2.

Если вы столкнулись с ошибкой `libnvidia-ml.so.1: cannot open shared object file: No such file or directory`, это означает, что NVIDIA Device Plugin не может найти библиотеки NVIDIA. Убедитесь, что:

1. Драйвер NVIDIA правильно установлен в WSL2
2. Библиотеки NVIDIA доступны по пути `/usr/lib/x86_64-linux-gnu` и `/usr/lib/wsl/lib`
3. Используется пользовательский манифест, который монтирует эти пути в контейнер

Для проверки наличия библиотек NVIDIA выполните:

```bash
ls -l /usr/lib/x86_64-linux-gnu/libnvidia-ml.so*
ls -l /usr/lib/wsl/lib/libnvidia-ml.so*
```

Если библиотеки отсутствуют, установите пакет NVIDIA Container Toolkit:

```bash
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
```

### Решение проблемы "ERROR_LIBRARY_NOT_FOUND"

Если вы видите ошибку `Failed to initialize NVML: ERROR_LIBRARY_NOT_FOUND` в логах NVIDIA Device Plugin, это означает, что библиотека NVML (libnvidia-ml.so.1) не найдена в контейнере.

Для решения этой проблемы:

1. Убедитесь, что драйвер NVIDIA правильно установлен в WSL2:
   ```bash
   nvidia-smi
   ```

2. Проверьте наличие библиотеки libnvidia-ml.so.1:
   ```bash
   find /usr -name "libnvidia-ml.so*"
   ```

3. Если библиотека не найдена, установите пакет NVIDIA Container Toolkit:
   ```bash
   sudo apt-get update
   sudo apt-get install -y nvidia-container-toolkit
   ```

4. Проверьте, что используется наша кастомизированная версия NVIDIA Device Plugin с дополнительными точками монтирования и переменными окружения.

5. Перезапустите NVIDIA Device Plugin:
   ```bash
   kubectl delete -f tools/k8s-kind-setup/nvidia-device-plugin-custom.yml
   kubectl apply -f tools/k8s-kind-setup/nvidia-device-plugin-custom.yml
   ```

6. Проверьте логи NVIDIA Device Plugin:
   ```bash
   kubectl logs -n kube-system -l name=nvidia-device-plugin-ds
   ```

7. Убедитесь, что используется правильный путь к бинарному файлу NVIDIA Device Plugin в манифесте:
   ```yaml
   command: ["/usr/bin/nvidia-device-plugin"]
   ```
   Бинарный файл находится в директории `/usr/bin/` контейнера.

## Устранение неполадок

> Для более подробной информации о решении проблем с GPU и других компонентов системы см. [Руководство по устранению неполадок](troubleshooting.md).

### Проблема: GPU не обнаруживается в WSL2

1. Проверьте, что драйвер NVIDIA установлен в Windows:
   ```bash
   # Проверка версии драйвера
   nvidia-smi | grep "Driver Version"
   ```

2. Проверьте настройку NVIDIA Container Toolkit:
   ```bash
   # Проверка базовой работы GPU в контейнере
   docker run --rm --gpus all nvidia/cuda:12.6.1-base-ubuntu22.04 nvidia-smi
   ```

3. Проверьте наличие достаточной памяти:
   ```bash
   # Проверка доступной памяти GPU
   nvidia-smi --query-gpu=memory.free,memory.total --format=csv
   ```

4. Проверьте настройки Docker:
   ```bash
   # Проверка настроек Docker для NVIDIA
   grep -r "nvidia-container-runtime" /etc/docker
   ```

### Проблема: Ошибки при запуске контейнеров с GPU

1. Перезапустите Docker:
   ```bash
   sudo systemctl restart docker
   ```

2. Проверьте логи Docker:
   ```bash
   sudo journalctl -u docker
   ```

3. Проверьте настройки NVIDIA Container Toolkit:
   ```bash
   sudo nvidia-ctk runtime configure --runtime=docker
   ```

4. Перезапустите WSL:
   ```bash
   # В PowerShell на Windows
   wsl --shutdown
   ```

### Проблема: Ошибка libnvidia-ml.so.1 в NVIDIA Device Plugin

Если вы видите ошибку `libnvidia-ml.so.1: cannot open shared object file: No such file or directory` в логах NVIDIA Device Plugin, это означает, что библиотеки NVIDIA не доступны в контейнере.

Для решения этой проблемы:

1. Запустите скрипт установки библиотек NVIDIA:

```bash
# Сделайте скрипт исполняемым
chmod +x tools/k8s-kind-setup/setup-nvidia-libs.sh

# Запустите скрипт
./tools/k8s-kind-setup/setup-nvidia-libs.sh
```

Этот скрипт:
- Устанавливает необходимые пакеты NVIDIA
- Проверяет наличие библиотеки libnvidia-ml.so.1
- Создает символические ссылки, если необходимо
- Настраивает NVIDIA Container Toolkit
- Проверяет работу GPU в контейнере

2. После успешного выполнения скрипта, перезапустите кластер KIND:

```bash
# Удалите существующий кластер
kind delete cluster --name kind

# Запустите скрипт настройки заново
./tools/k8s-kind-setup/deploy-all/src/deploy-all.sh --auto-install
```