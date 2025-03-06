# Доступ к Open WebUI из локальной сети

Данный документ содержит инструкции по настройке доступа к Open WebUI из локальной сети для различных сценариев развертывания.

## Навигация
- [Главная страница](../README.md)
- Документация
  - [Руководство по развертыванию](DEPLOYMENT.md)
  - [GitOps подход](GITOPS.md)
  - [API Reference](api.md)
  - [Устранение неполадок](troubleshooting.md)
  - [GPU в WSL2](GPU-WSL.md)
  - [Использование Docker](DOCKER-USAGE.md)
  - [Настройка KUBECONFIG](KUBECONFIG.md)
  - [Мониторинг](MONITORING.md)
  - [Настройка сети](NETWORK-CONFIGURATION.md)
  - [Доступ к Open WebUI из локальной сети](ACCESSING-OPEN-WEBUI.md) (текущий документ)
  - [Миграция и настройка WSL и Docker](WSL-DOCKER-MIGRATION.md)
- [Примеры](../examples/README.md)

## Содержание

- [Обзор](#обзор)
- [Доступ к Open WebUI в Kubernetes](#доступ-к-open-webui-в-kubernetes)
  - [Метод 1: Использование NodePort](#метод-1-использование-nodeport)
  - [Метод 2: Использование LoadBalancer](#метод-2-использование-loadbalancer)
  - [Метод 3: Использование Ingress с внешним доступом](#метод-3-использование-ingress-с-внешним-доступом)
  - [Метод 4: Port-forwarding](#метод-4-port-forwarding)
- [Доступ к Open WebUI в Docker](#доступ-к-open-webui-в-docker)
  - [Настройка Docker Compose](#настройка-docker-compose)
  - [Проброс портов в Docker](#проброс-портов-в-docker)
- [Доступ к Open WebUI в WSL2](#доступ-к-open-webui-в-wsl2)
  - [Настройка проброса портов из WSL2 в Windows](#настройка-проброса-портов-из-wsl2-в-windows)
  - [Доступ из локальной сети к WSL2](#доступ-из-локальной-сети-к-wsl2)
- [Настройка DNS и hosts](#настройка-dns-и-hosts)
- [Настройка безопасности](#настройка-безопасности)
  - [Базовая аутентификация](#базовая-аутентификация)
  - [HTTPS и TLS](#https-и-tls)
- [Решение проблем](#решение-проблем)

## Обзор

Open WebUI — это веб-интерфейс для взаимодействия с Ollama и другими LLM-сервисами. По умолчанию, Open WebUI доступен только на локальном компьютере, где он запущен. Для доступа из локальной сети требуется дополнительная настройка в зависимости от способа развертывания.

## Доступ к Open WebUI в Kubernetes

### Метод 1: Использование NodePort

Самый простой способ сделать Open WebUI доступным в локальной сети — изменить тип сервиса на NodePort.

1. Отредактируйте values.yaml для open-webui или используйте параметр --set при установке Helm-чарта:

```bash
helm upgrade --install open-webui ./helm-charts/open-webui -n prod --set service.type=NodePort --set service.nodePort=30080
```

2. Или отредактируйте существующий сервис:

```bash
kubectl patch svc open-webui -n prod -p '{"spec": {"type": "NodePort", "ports": [{"port": 3000, "nodePort": 30080}]}}'
```

После этого Open WebUI будет доступен по адресу `http://<IP-адрес-узла>:30080`, где `<IP-адрес-узла>` — это IP-адрес любого узла кластера Kubernetes.

### Метод 2: Использование LoadBalancer

Если у вас есть поддержка LoadBalancer в кластере (например, через MetalLB в локальной среде):

1. Установите или обновите Helm-чарт с типом сервиса LoadBalancer:

```bash
helm upgrade --install open-webui ./helm-charts/open-webui -n prod --set service.type=LoadBalancer
```

2. Проверьте назначенный IP-адрес:

```bash
kubectl get svc open-webui -n prod
```

Open WebUI будет доступен по адресу `http://<external-ip>:3000`, где `<external-ip>` — это внешний IP-адрес, назначенный LoadBalancer.

### Метод 3: Использование Ingress с внешним доступом

Если у вас настроен Ingress-контроллер с доступом из локальной сети:

1. Убедитесь, что Ingress включен в values.yaml:

```yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: webui.local
      paths:
        - path: /
          pathType: Prefix
```

2. Установите или обновите Helm-чарт:

```bash
helm upgrade --install open-webui ./helm-charts/open-webui -n prod -f values.yaml
```

3. Настройте DNS или файл hosts на клиентских компьютерах, добавив запись:

```
<IP-адрес-ingress-контроллера> webui.local
```

После этого Open WebUI будет доступен по адресу `http://webui.local` из любого компьютера в локальной сети.

### Метод 4: Port-forwarding

Временное решение для быстрого доступа без изменения конфигурации:

```bash
kubectl port-forward svc/open-webui -n prod 3000:3000 --address 0.0.0.0
```

Эта команда сделает Open WebUI доступным по адресу `http://<IP-адрес-компьютера>:3000` в локальной сети, но только пока команда выполняется.

## Доступ к Open WebUI в Docker

### Настройка Docker Compose

Для доступа к Open WebUI, запущенному через Docker Compose, отредактируйте файл docker-compose.yaml:

1. Добавьте сервис open-webui в существующий docker-compose.yaml:

```yaml
services:
  ollama:
    # ... существующая конфигурация ollama ...
    networks:
      - ollama-network

  open-webui:
    image: ghcr.io/open-webui/open-webui:latest
    container_name: open-webui
    restart: unless-stopped
    ports:
      - "3000:3000"  # Проброс порта на хост-машину
    environment:
      - OLLAMA_API_BASE=http://ollama:11434/api
      - OLLAMA_BASE_URL=http://ollama:11434
      - OLLAMA_HOST=ollama
      - OLLAMA_PORT=11434
      - HOST=0.0.0.0  # Важно для доступа извне контейнера
    networks:
      - ollama-network
    depends_on:
      - ollama

networks:
  ollama-network:
    name: ollama-network
    driver: bridge
```

2. Запустите контейнеры:

```bash
docker-compose up -d
```

После этого Open WebUI будет доступен по адресу `http://<IP-адрес-хоста>:3000` в локальной сети.

### Проброс портов в Docker

Если вы запускаете контейнер напрямую через Docker:

```bash
docker run -d --name open-webui \
  --network ollama-network \
  -p 3000:3000 \
  -e OLLAMA_API_BASE=http://ollama:11434/api \
  -e OLLAMA_BASE_URL=http://ollama:11434 \
  -e OLLAMA_HOST=ollama \
  -e OLLAMA_PORT=11434 \
  -e HOST=0.0.0.0 \
  ghcr.io/open-webui/open-webui:latest
```

## Доступ к Open WebUI в WSL2

### Настройка проброса портов из WSL2 в Windows

Если Open WebUI запущен в WSL2, необходимо настроить проброс портов из WSL2 в Windows:

1. Получите IP-адрес WSL2:

```powershell
# PowerShell
$wslIp = (wsl hostname -I).Trim()
echo $wslIp
```

2. Настройте проброс порта 3000:

```powershell
# PowerShell (от имени администратора)
netsh interface portproxy add v4tov4 listenport=3000 listenaddress=0.0.0.0 connectport=3000 connectaddress=$wslIp
```

3. Разрешите входящие подключения в брандмауэре Windows:

```powershell
# PowerShell (от имени администратора)
New-NetFirewallRule -DisplayName "WSL2 Open WebUI" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3000
```

После этого Open WebUI будет доступен по адресу `http://<IP-адрес-Windows>:3000` из локальной сети.

### Доступ из локальной сети к WSL2

#### Для Windows 11 с режимом Mirrored

В Windows 11 22H2 и выше доступен режим Mirrored, который позволяет напрямую обращаться к сервисам WSL2 из локальной сети:

1. Настройте режим Mirrored в файле `.wslconfig`:

```ini
[wsl2]
networkingMode=mirrored
```

2. Настройте брандмауэр Hyper-V:

```powershell
# PowerShell (от имени администратора)
Set-NetFirewallHyperVVMSetting -Name '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -DefaultInboundAction Allow
```

3. Перезапустите WSL:

```powershell
# PowerShell (от имени администратора)
wsl --shutdown
wsl
```

После этого Open WebUI будет доступен по адресу `http://<IP-адрес-WSL2>:3000` из локальной сети.

## Настройка DNS и hosts

Для удобного доступа к Open WebUI по имени вместо IP-адреса:

1. Настройте файл hosts на клиентских компьютерах:

```
# Windows: C:\Windows\System32\drivers\etc\hosts
# Linux/Mac: /etc/hosts
<IP-адрес-сервера> webui.local
```

2. Или настройте локальный DNS-сервер (например, dnsmasq или Pi-hole):

```
address=/webui.local/<IP-адрес-сервера>
```

## Настройка безопасности

### Базовая аутентификация

Для защиты доступа к Open WebUI можно настроить базовую аутентификацию:

1. В Kubernetes с Ingress:

```yaml
ingress:
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
```

2. Создайте секрет с учетными данными:

```bash
htpasswd -c auth admin
kubectl create secret generic basic-auth --from-file=auth -n prod
```

### HTTPS и TLS

Для безопасного доступа по HTTPS:

1. В Kubernetes с Ingress и cert-manager:

```yaml
ingress:
  tls:
    - hosts:
        - webui.local
      secretName: webui-tls
```

2. Для Docker и прямого доступа рекомендуется использовать обратный прокси, например, Nginx или Traefik с настроенным SSL/TLS.

## Решение проблем

### Проблема: Open WebUI недоступен из локальной сети

**Решение:**

1. Проверьте, что сервис прослушивает на всех интерфейсах (0.0.0.0), а не только на localhost (127.0.0.1)
2. Проверьте настройки брандмауэра на сервере
3. Убедитесь, что порт проброшен корректно
4. Проверьте сетевые настройки в Docker или Kubernetes

### Проблема: Не работает доступ по имени хоста

**Решение:**

1. Проверьте настройки DNS или файла hosts
2. Убедитесь, что Ingress-контроллер настроен правильно
3. Проверьте, что DNS-сервер доступен для клиентских компьютеров

### Проблема: Медленная работа Open WebUI через сеть

**Решение:**

1. Увеличьте лимиты ресурсов для пода или контейнера
2. Настройте кэширование в Ingress-контроллере
3. Оптимизируйте параметры сети в Kubernetes или Docker