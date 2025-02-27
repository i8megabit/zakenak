# Настройка сети для Zakenak

Данный документ содержит подробную информацию о настройке сети для корректной работы Zakenak в различных окружениях, включая WSL2 в Windows 11 и управление хостами.

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
  - [Настройка сети](NETWORK-CONFIGURATION.md) (текущий документ)
- [Примеры](../examples/README.md)

## Содержание

- [Настройка сети в WSL2 на Windows 11](#настройка-сети-в-wsl2-на-windows-11)
  - [Базовая конфигурация WSL2](#базовая-конфигурация-wsl2)
  - [Настройка статического IP для WSL2](#настройка-статического-ip-для-wsl2)
  - [Проброс портов](#проброс-портов)
- [Настройка файла hosts в Linux](#настройка-файла-hosts-в-linux)
  - [Структура файла /etc/hosts](#структура-файла-etchosts)
  - [Примеры конфигурации](#примеры-конфигурации-etchosts)
- [Настройка файла hosts в Windows](#настройка-файла-hosts-в-windows)
  - [Расположение и структура файла](#расположение-и-структура-файла)
  - [Примеры конфигурации](#примеры-конфигурации-hosts-windows)
- [Интеграция сети между Windows и WSL2](#интеграция-сети-между-windows-и-wsl2)
- [Решение проблем с сетью](#решение-проблем-с-сетью)

## Настройка сети в WSL2 на Windows 11

### Базовая конфигурация WSL2

WSL2 использует виртуальный сетевой адаптер и NAT для связи с хост-системой Windows. По умолчанию, WSL2 получает динамический IP-адрес при каждом запуске, что может вызывать проблемы при настройке сервисов.

Для настройки базовых параметров сети WSL2, создайте или отредактируйте файл `.wslconfig` в домашнем каталоге пользователя Windows:

```powershell
# PowerShell (от имени администратора)
notepad "$env:USERPROFILE\.wslconfig"
```

Добавьте следующие настройки:

```ini
[wsl2]
memory=8GB
processors=4
localhostForwarding=true
networkingMode=mirrored
dnsTunneling=true
firewall=true
```

Параметры:
- `memory`: Ограничение памяти для WSL2
- `processors`: Количество процессоров
- `localhostForwarding`: Включает перенаправление localhost
- `networkingMode`: Режим сети (mirrored - рекомендуемый для Windows 11)
- `dnsTunneling`: Улучшает разрешение DNS
- `firewall`: Интеграция с брандмауэром Windows

После изменения конфигурации перезапустите WSL:

```powershell
# PowerShell (от имени администратора)
wsl --shutdown
wsl
```

### Настройка статического IP для WSL2

Для настройки статического IP в WSL2, создайте скрипт в Linux-дистрибутиве:

```bash
# В WSL2 (Ubuntu)
sudo nano /etc/wsl-init.sh
```

Содержимое скрипта:

```bash
#!/bin/bash
# Настройка статического IP для WSL2
ip addr add 192.168.50.2/24 dev eth0
ip route add default via 192.168.50.1 dev eth0
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

Сделайте скрипт исполняемым и добавьте его в автозагрузку:

```bash
sudo chmod +x /etc/wsl-init.sh
echo "/etc/wsl-init.sh" | sudo tee -a /etc/wsl.conf
```

### Проброс портов

Для автоматического проброса портов из WSL2 в Windows создайте PowerShell скрипт:

```powershell
# port-forward.ps1
$wslIp = (wsl hostname -I).Trim()
$ports = @(80, 443, 8080, 3000, 8443)

foreach ($port in $ports) {
    netsh interface portproxy delete v4tov4 listenport=$port listenaddress=0.0.0.0 | Out-Null
    netsh interface portproxy add v4tov4 listenport=$port listenaddress=0.0.0.0 connectport=$port connectaddress=$wslIp
}

# Разрешить входящие подключения в брандмауэре
New-NetFirewallRule -DisplayName "WSL2 Port Forwarding" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $ports -ErrorAction SilentlyContinue
```

Запустите скрипт от имени администратора:

```powershell
# PowerShell (от имени администратора)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\port-forward.ps1
```

## Настройка файла hosts в Linux

### Структура файла /etc/hosts

Файл `/etc/hosts` в Linux используется для сопоставления имен хостов с IP-адресами. Это позволяет обращаться к серверам по имени вместо IP-адреса.

Базовая структура файла:

```
# /etc/hosts
127.0.0.1       localhost
127.0.1.1       ubuntu

# Пользовательские записи
192.168.1.100   server1
192.168.1.101   server2
```

### Примеры конфигурации /etc/hosts

Пример конфигурации для работы с Kubernetes в WSL2:

```
# /etc/hosts
127.0.0.1       localhost
127.0.1.1       ubuntu

# Kubernetes кластер
192.168.50.2    k8s-master
192.168.50.3    k8s-worker1
192.168.50.4    k8s-worker2

# Сервисы Kubernetes
127.0.0.1       kubernetes.docker.internal
127.0.0.1       registry.local
127.0.0.1       dashboard.local
127.0.0.1       prometheus.local
127.0.0.1       grafana.local
127.0.0.1       ollama.local
127.0.0.1       webui.local

# Интеграция с Windows
192.168.1.100   windows-host
```

Для редактирования файла hosts в Linux используйте:

```bash
sudo nano /etc/hosts
```

После внесения изменений очистите DNS-кеш:

```bash
sudo systemd-resolve --flush-caches
```

## Настройка файла hosts в Windows

### Расположение и структура файла

В Windows файл hosts находится по пути `C:\Windows\System32\drivers\etc\hosts`. Структура файла аналогична Linux.

Базовая структура файла:

```
# C:\Windows\System32\drivers\etc\hosts
127.0.0.1       localhost
::1             localhost

# Пользовательские записи
192.168.1.100   server1
192.168.1.101   server2
```

### Примеры конфигурации hosts Windows

Пример конфигурации для работы с WSL2 и Kubernetes:

```
# C:\Windows\System32\drivers\etc\hosts
127.0.0.1       localhost
::1             localhost

# WSL2 интеграция
172.22.53.2     wsl2
172.22.53.2     ubuntu

# Kubernetes сервисы
127.0.0.1       kubernetes.docker.internal
127.0.0.1       registry.local
127.0.0.1       dashboard.local
127.0.0.1       prometheus.local
127.0.0.1       grafana.local
127.0.0.1       ollama.local
127.0.0.1       webui.local

# Локальная разработка
127.0.0.1       dev.local
127.0.0.1       api.local
```

Для редактирования файла hosts в Windows:

1. Откройте Блокнот от имени администратора
2. Откройте файл `C:\Windows\System32\drivers\etc\hosts`
3. Внесите необходимые изменения и сохраните файл

После внесения изменений очистите DNS-кеш:

```powershell
# PowerShell (от имени администратора)
ipconfig /flushdns
```

## Интеграция сети между Windows и WSL2

Для обеспечения бесшовной интеграции между Windows и WSL2 рекомендуется:

1. Настроить одинаковые записи в файлах hosts обеих систем
2. Использовать режим сети `mirrored` в WSL2 (доступно в Windows 11)
3. Настроить проброс портов для сервисов

Пример скрипта для синхронизации hosts между Windows и WSL2:

```powershell
# sync-hosts.ps1
$windowsHosts = "C:\Windows\System32\drivers\etc\hosts"
$wslHosts = "\\wsl$\Ubuntu\etc\hosts"

# Копирование общих записей из Windows в WSL
$commonEntries = Get-Content $windowsHosts | Where-Object { $_ -match "^[0-9]" -and $_ -notmatch "localhost" }
$commonEntries | ForEach-Object {
    wsl -d Ubuntu -u root bash -c "grep -q '$_' /etc/hosts || echo '$_' >> /etc/hosts"
}

# Очистка DNS-кеша
ipconfig /flushdns
wsl -d Ubuntu -u root systemd-resolve --flush-caches
```

## Решение проблем с сетью

> Для более подробной информации о решении различных проблем с системой см. [Руководство по устранению неполадок](troubleshooting.md).

### Проблема: WSL2 не имеет доступа к интернету

**Решение:**

```bash
# В WSL2
sudo rm /etc/resolv.conf
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
sudo bash -c 'echo "[network]" > /etc/wsl.conf'
sudo bash -c 'echo "generateResolvConf = false" >> /etc/wsl.conf'
```

### Проблема: Не работает проброс портов из WSL2 в Windows

**Решение:**

1. Проверьте IP-адрес WSL2:
   ```bash
   # В WSL2
   ip addr show eth0
   ```

2. Обновите правила проброса портов:
   ```powershell
   # PowerShell (от имени администратора)
   $wslIp = (wsl hostname -I).Trim()
   $port = 80
   netsh interface portproxy delete v4tov4 listenport=$port listenaddress=0.0.0.0
   netsh interface portproxy add v4tov4 listenport=$port listenaddress=0.0.0.0 connectport=$port connectaddress=$wslIp
   ```

3. Проверьте настройки брандмауэра:
   ```powershell
   # PowerShell (от имени администратора)
   New-NetFirewallRule -DisplayName "WSL2 Port Forwarding" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 80 -ErrorAction SilentlyContinue
   ```

### Проблема: Не работает разрешение имен хостов

**Решение:**

1. Проверьте файлы hosts в обеих системах
2. Очистите DNS-кеш:
   ```powershell
   # PowerShell (от имени администратора)
   ipconfig /flushdns
   ```
   ```bash
   # В WSL2
   sudo systemd-resolve --flush-caches
   ```
3. Проверьте разрешение имен:
   ```bash
   # В WSL2
   nslookup example.com
   ```