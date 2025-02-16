# Руководство по развертыванию Ƶakenak™®
```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

Should Harbour?	No.
```
## Подготовка окружения

### Требования к системе
- Windows 11 с WSL2
- NVIDIA GPU с поддержкой CUDA
- Docker Desktop с поддержкой WSL2
- Kubernetes 1.25+
- Helm 3.x
- Go 1.21+

### Установка CUDA в WSL2
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

## Создание кластера

### Настройка Kind
```bash
# Создание кластера с поддержкой GPU
kind create cluster --config helm-charts/kind-config.yaml

# Проверка статуса
kubectl get nodes
kubectl get pods -A
```

### Установка компонентов

1. Установка cert-manager:
```bash
helm upgrade --install \
	cert-manager ./helm-charts/cert-manager \
	--namespace prod \
	--create-namespace
```

2. Установка локального CA:
```bash
helm upgrade --install \
	local-ca ./helm-charts/local-ca \
	--namespace prod
```

3. Установка Ollama:
```bash
helm upgrade --install \
	ollama ./helm-charts/ollama \
	--namespace prod
```

4. Установка Open WebUI:
```bash
helm upgrade --install \
	open-webui ./helm-charts/open-webui \
	--namespace prod
```

## Проверка установки

### Проверка сертификатов
```bash
kubectl get certificates -n prod
kubectl get secrets -n prod
```

### Проверка GPU
```bash
# Проверка статуса GPU
kubectl exec -it deployment/ollama -n prod -- nvidia-smi

# Проверка CUDA
kubectl exec -it deployment/ollama -n prod -- nvcc --version
```

### Проверка доступности сервисов
```bash
# Получение IP адресов
kubectl get ingress -n prod

# Проверка DNS
nslookup ollama.prod.local
nslookup webui.prod.local
```

## Настройка DNS

### Локальное разрешение имен
Добавьте в `/etc/hosts`:
```
127.0.0.1 ollama.prod.local
127.0.0.1 webui.prod.local
```

### CoreDNS
Проверьте применение конфигурации CoreDNS:
```bash
kubectl get configmap coredns -n kube-system -o yaml
```

## Мониторинг

### Логи
```bash
# Логи Ollama
kubectl logs -f deployment/ollama -n prod

# Логи WebUI
kubectl logs -f deployment/open-webui -n prod
```

### Метрики GPU
```bash
# Использование GPU
kubectl exec -it deployment/ollama -n prod -- nvidia-smi dmon

# Мониторинг памяти
kubectl exec -it deployment/ollama -n prod -- nvidia-smi --query-gpu=memory.used,memory.total --format=csv
```

## Обновление

### Обновление компонентов
```bash
# Обновление всех компонентов
make deploy

# Обновление отдельного компонента
helm upgrade ollama ./helm-charts/ollama -n prod
```

### Откат изменений
```bash
# Просмотр истории релизов
helm history ollama -n prod

# Откат к предыдущей версии
helm rollback ollama 1 -n prod
```

## Устранение неполадок

### Проблемы с GPU
1. Проверьте наличие драйверов NVIDIA в WSL2
2. Убедитесь, что CUDA toolkit установлен и доступен
3. Проверьте монтирование устройств GPU в kind-config.yaml

### Проблемы с сертификатами
1. Проверьте статус cert-manager
2. Проверьте логи cert-manager
3. Проверьте конфигурацию ClusterIssuer

### Сетевые проблемы
1. Проверьте настройки Ingress
2. Проверьте конфигурацию CoreDNS
3. Проверьте сетевые политики

## Безопасность

### TLS сертификаты
- Все сервисы используют TLS
- Сертификаты автоматически обновляются
- Используется локальный CA

### Сетевые политики
- Изоляция подов по namespace
- Ограничение доступа к GPU
- Контроль входящего трафика

```plain text
Copyright (c)  2025 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

The name "Zakenak" and associated branding are trademarks of @eberil and may not be used without express written permission.
```