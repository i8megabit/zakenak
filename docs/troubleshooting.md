# Руководство по устранению неполадок

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
  - [Руководство по развертыванию](DEPLOYMENT.md)
  - [GitOps подход](GITOPS.md)
  - [API Reference](api.md)
  - [Устранение неполадок](troubleshooting.md) (текущий документ)
  - [GPU в WSL2](GPU-WSL.md)
  - [Использование Docker](DOCKER-USAGE.md)
  - [Настройка KUBECONFIG](KUBECONFIG.md)
  - [Мониторинг](MONITORING.md)
  - [Настройка сети](NETWORK-CONFIGURATION.md)
- [Примеры](../examples/README.md)

## Содержание
1. [Проблемы с GPU](#проблемы-с-gpu)
2. [Проблемы с сертификатами](#проблемы-с-сертификатами)
3. [Сетевые проблемы](#сетевые-проблемы)
4. [Проблемы с WSL2](#проблемы-с-wsl2)
5. [Проблемы с Kubernetes](#проблемы-с-kubernetes)
6. [Проблемы с Helm](#проблемы-с-helm)
7. [Проблемы с Docker](#проблемы-с-docker)

## Проблемы с GPU

> Для подробной информации о настройке и использовании GPU в WSL2 см. [GPU в WSL2](GPU-WSL.md).

### Проверка драйверов NVIDIA
```bash
# Проверка наличия и версии драйвера
nvidia-smi

# Проверка GPU в контейнере
docker run --rm --gpus all nvidia/cuda:12.6.1-base-ubuntu22.04 nvidia-smi
```

### Проблема: GPU не определяется в WSL2
1. Убедитесь, что у вас установлен драйвер NVIDIA версии 535.104.05 или выше
2. Проверьте, что WSL2 интеграция включена в настройках NVIDIA Control Panel
3. Перезапустите WSL2: `wsl --shutdown` и затем запустите Ubuntu снова
4. Проверьте, что NVIDIA Container Toolkit установлен и настроен

### Проблема: GPU не определяется в кластере
1. Проверьте, что узлы помечены меткой `nvidia.com/gpu=true`:
   ```bash
   kubectl get nodes -l nvidia.com/gpu=true
   ```
2. Проверьте, что NVIDIA device plugin запущен:
   ```bash
   kubectl get pods -n kube-system -l k8s-app=nvidia-device-plugin-daemonset
   ```
3. Проверьте логи NVIDIA device plugin:
   ```bash
   kubectl logs -n kube-system -l k8s-app=nvidia-device-plugin-daemonset
   ```

### Проблема: Ollama не использует GPU
1. Проверьте, что под Ollama запущен на узле с GPU:
   ```bash
   kubectl describe pod -n prod -l app=ollama
   ```
2. Проверьте, что в поде Ollama запрошены GPU ресурсы:
   ```bash
   kubectl describe pod -n prod -l app=ollama | grep -A 5 "Limits:"
   ```
3. Проверьте логи Ollama:
   ```bash
   kubectl logs -n prod -l app=ollama
   ```

### Проблемы с CPU-only режимом
1. Проверьте, что переменная окружения GPU_ENABLED установлена правильно:
   ```bash
   echo $GPU_ENABLED
   ```
2. Если вы хотите использовать CPU-only режим, установите:
   ```bash
   export GPU_ENABLED=false
   ```
3. Если вы хотите использовать GPU, установите:
   ```bash
   export GPU_ENABLED=true
   ```
4. Проверьте, что скрипт deploy-all.sh запускается с правильными параметрами:
   ```bash
   # Для CPU-only режима
   ./tools/k8s-kind-setup/deploy-all/src/deploy-all.sh --skip-gpu-check --skip-tensor-check
   
   # Для режима с GPU
   ./tools/k8s-kind-setup/deploy-all/src/deploy-all.sh
   ```
5. Если под зависает при проверке тензорных операций, перезапустите скрипт с параметром --skip-tensor-check:
   ```bash
   ./tools/k8s-kind-setup/deploy-all/src/deploy-all.sh --skip-tensor-check
   ```

## Проблемы с сертификатами

### Проверка состояния сертификатов
```bash
# Проверка сертификатов
kubectl get certificates -n prod

# Проверка запросов на сертификаты
kubectl get certificaterequests -n prod

# Проверка секретов с сертификатами
kubectl get secrets -n prod
```

### Проблема: Сертификаты не выпускаются
1. Проверьте, что cert-manager запущен:
   ```bash
   kubectl get pods -n cert-manager
   ```
2. Проверьте логи cert-manager:
   ```bash
   kubectl logs -n cert-manager -l app=cert-manager
   ```
3. Проверьте, что ClusterIssuer настроен правильно:
   ```bash
   kubectl describe clusterissuer -n prod
   ```

### Проблема: TLS ошибки в Ingress
1. Проверьте, что секрет с сертификатом существует:
   ```bash
   kubectl describe secret -n prod tls-secret
   ```
2. Проверьте, что Ingress настроен на использование правильного секрета:
   ```bash
   kubectl describe ingress -n prod
   ```
3. Проверьте логи Ingress контроллера:
   ```bash
   kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
   ```

## Сетевые проблемы

### Проверка DNS
```bash
# Проверка DNS резолвинга
kubectl run -it --rm debug --image=busybox -- nslookup kubernetes.default

# Проверка CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns
```

### Проблема: Сервисы недоступны через Ingress
1. Проверьте, что Ingress контроллер запущен:
   ```bash
   kubectl get pods -n ingress-nginx
   ```
2. Проверьте, что Ingress ресурс создан и настроен правильно:
   ```bash
   kubectl get ingress -n prod
   kubectl describe ingress -n prod
   ```
3. Проверьте, что сервис доступен внутри кластера:
   ```bash
   kubectl run -it --rm debug --image=busybox -- wget -O- http://service-name.prod.svc.cluster.local:port
   ```

### Проблема: NetworkPolicy блокирует трафик
1. Проверьте, какие NetworkPolicy применены:
   ```bash
   kubectl get networkpolicies -n prod
   ```
2. Проверьте, что NetworkPolicy настроена правильно:
   ```bash
   kubectl describe networkpolicy -n prod
   ```
3. Временно отключите NetworkPolicy для проверки:
   ```bash
   kubectl delete networkpolicy -n prod policy-name
   ```

### Проблема: DNS не работает в подах при использовании режима mirrored в WSL2
1. Проверьте текущий режим сети WSL2:
   ```powershell
   # В PowerShell на Windows
   Get-Content "$env:USERPROFILE\.wslconfig" | Select-String "networkingMode"
   ```
2. Проверьте IP-адреса, используемые для DNS резолвинга:
   ```bash
   # В WSL2
   source /tmp/tmpqzgh4nhl_run_i8megabit_k8s_issue_72_fa470057/tools/k8s-kind-setup/env/src/env.sh
   echo "Режим сети: $(detect_wsl_network_mode)"
   echo "IP для DNS: $(get_dns_ip)"
   ```
3. Проверьте конфигурацию CoreDNS:
   ```bash
   kubectl get configmap -n kube-system coredns -o yaml
   kubectl get configmap -n kube-system coredns-custom -o yaml
   ```
4. Проверьте DNS резолвинг внутри пода:
   ```bash
   kubectl run -it --rm --restart=Never --image=busybox:1.28 dns-test -- nslookup ollama.prod.local
   ```
5. Если проблема сохраняется, попробуйте переключиться на режим NAT:
   ```powershell
   # В PowerShell на Windows (от имени администратора)
   $wslconfig = Get-Content "$env:USERPROFILE\.wslconfig"
   $wslconfig = $wslconfig -replace "networkingMode=mirrored", "networkingMode=NAT"
   Set-Content -Path "$env:USERPROFILE\.wslconfig" -Value $wslconfig
   wsl --shutdown
   ```
   После перезапуска WSL2 повторите развертывание кластера.

### Проблема: API сервер Kubernetes недоступен на порту 6443 при использовании режима mirrored
1. Проверьте доступность API сервера через localhost:
   ```bash
   curl -k https://localhost:6443
   ```
2. Проверьте доступность API сервера через IP-адрес хоста:
   ```bash
   # Получение IP-адреса хоста
   HOST_IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -n 1)
   curl -k https://${HOST_IP}:6443
   ```
3. Проверьте настройки брандмауэра Windows:
   ```powershell
   # В PowerShell на Windows (от имени администратора)
   New-NetFirewallRule -DisplayName "Kubernetes API" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 6443
   ```
4. Если проблема сохраняется, попробуйте переключиться на режим NAT:
   ```powershell
   # В PowerShell на Windows (от имени администратора)
   $wslconfig = Get-Content "$env:USERPROFILE\.wslconfig"
   $wslconfig = $wslconfig -replace "networkingMode=mirrored", "networkingMode=NAT"
   Set-Content -Path "$env:USERPROFILE\.wslconfig" -Value $wslconfig
   wsl --shutdown
   ```
   После перезапуска WSL2 повторите развертывание кластера.

## Проблемы с WSL2

### Проверка состояния WSL2
```bash
# Проверка версии WSL
wsl --version

# Проверка статуса WSL
wsl --status

# Проверка дистрибутивов
wsl --list --verbose
```

### Проблема: WSL2 не запускается
1. Перезапустите службу WSL:
   ```powershell
   Restart-Service LxssManager
   ```
2. Обновите WSL:
   ```powershell
   wsl --update
   ```
3. Проверьте настройки в .wslconfig:
   ```
   %UserProfile%\.wslconfig
   ```

### Проблема: Проблемы с памятью в WSL2
1. Настройте лимиты памяти в .wslconfig:
   ```
   [wsl2]
   memory=16GB
   swap=8GB
   ```
2. Перезапустите WSL:
   ```powershell
   wsl --shutdown
   ```

## Проблемы с Kubernetes

### Проверка состояния кластера
```bash
# Проверка статуса кластера
kubectl cluster-info

# Проверка узлов
kubectl get nodes

# Проверка подов
kubectl get pods --all-namespaces
```

### Проблема: Кластер Kind не запускается
1. Проверьте, что Docker запущен и работает
2. Удалите существующий кластер и создайте новый:
   ```bash
   kind delete cluster --name kind
   kind create cluster --config tools/k8s-kind-setup/kind/config/kind-config-gpu.yml
   ```
3. Проверьте логи Kind:
   ```bash
   docker logs kind-control-plane
   ```
4. Если вы видите ошибку "could not find a log line that matches "Reached target .*Multi-User System.*|detected cgroup v1"", это связано с проблемой cgroup в WSL2:
   - Убедитесь, что Docker настроен на использование systemd в качестве cgroup driver:
     ```bash
     cat /etc/docker/daemon.json
     ```
     Файл должен содержать:
     ```json
     {
       "exec-opts": ["native.cgroupdriver=systemd"],
       "log-driver": "json-file",
       "log-opts": {
         "max-size": "100m"
       }
     }
     ```
   - Проверьте настройки WSL в %UserProfile%\.wslconfig на Windows:
     ```powershell
     # В PowerShell на Windows
     Get-Content "$env:USERPROFILE\.wslconfig"
     ```
     Файл должен содержать:
     ```
     [boot]
     systemd=true

     [wsl2]
     kernelCommandLine = cgroup_no_v1=all cgroup_enable=memory swapaccount=1
     ```
   - Перезапустите Docker и WSL:
     ```bash
     sudo systemctl restart docker
     # В PowerShell на Windows
     wsl --shutdown
     ```

### Проблема: Поды в состоянии Pending
1. Проверьте, что у узлов достаточно ресурсов:
   ```bash
   kubectl describe nodes
   ```
2. Проверьте, что PersistentVolumeClaim привязаны:
   ```bash
   kubectl get pvc -n prod
   ```
3. Проверьте события пода:
   ```bash
   kubectl describe pod -n prod pod-name
   ```

## Проблемы с Helm

### Проверка состояния Helm
```bash
# Проверка версии Helm
helm version

# Проверка репозиториев
helm repo list

# Проверка релизов
helm list -n prod
```

### Проблема: Ошибки при установке чартов
1. Проверьте, что чарт валиден:
   ```bash
   helm lint ./helm-charts/chart-name
   ```
2. Проверьте, что values.yaml содержит корректные значения:
   ```bash
   helm template ./helm-charts/chart-name --values ./helm-charts/chart-name/values.yaml
   ```
3. Попробуйте установить чарт с флагом --debug:
   ```bash
   helm install chart-name ./helm-charts/chart-name -n prod --debug
   ```

### Проблема: Ошибки при обновлении чартов
1. Проверьте историю релиза:
   ```bash
   helm history chart-name -n prod
   ```
2. Откатите релиз к предыдущей версии:
   ```bash
   helm rollback chart-name 1 -n prod
   ```
3. Удалите релиз и установите заново:
   ```bash
   helm uninstall chart-name -n prod
   helm install chart-name ./helm-charts/chart-name -n prod
   ```

## Проблемы с Docker

### Проверка состояния Docker
```bash
# Проверка версии Docker
docker version

# Проверка статуса Docker
docker info

# Проверка контейнеров
docker ps
```

### Проблема: Docker не запускается в WSL2
1. Проверьте, что служба Docker запущена:
   ```bash
   sudo service docker status
   ```
2. Запустите службу Docker:
   ```bash
   sudo service docker start
   ```
3. Проверьте, что пользователь добавлен в группу docker:
   ```bash
   sudo usermod -aG docker $USER
   ```

### Проблема: Ошибки при работе с GPU в Docker
1. Проверьте, что NVIDIA Container Toolkit установлен:
   ```bash
   nvidia-ctk --version
   ```
2. Настройте Docker для работы с NVIDIA Container Toolkit:
   ```bash
   sudo nvidia-ctk runtime configure --runtime=docker
   ```
3. Перезапустите Docker:
   ```bash
   sudo systemctl restart docker
   ```

```plain text
Copyright (c) 2025 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. 
See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT.
```