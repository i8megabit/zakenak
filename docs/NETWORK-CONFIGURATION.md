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
  - [Миграция и настройка WSL и Docker](WSL-DOCKER-MIGRATION.md)
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

### Режимы сети WSL2

WSL2 поддерживает два режима сети:

1. **Режим NAT (по умолчанию)**:
   - WSL2 использует виртуальный сетевой адаптер с NAT для связи с хост-системой Windows
   - Localhost (127.0.0.1) в WSL2 относится только к самой WSL2
   - Для доступа к сервисам WSL2 из Windows используется IP-адрес WSL2

2. **Режим Mirrored (Windows 11 22H2 и выше)**:
   - Сеть "зеркалируется" между Windows и WSL2
   - Localhost (127.0.0.1) в WSL2 может ссылаться на сервисы как в WSL2, так и в Windows
   - Порты, открытые в WSL2, автоматически доступны в Windows и наоборот
   - Поддержка IPv6
   - Улучшенная совместимость с VPN
   - Поддержка мультикаста
   - Возможность подключения к WSL2 напрямую из локальной сети (LAN)

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
memory=24GB
processors=8
swap=8GB
localhostForwarding=true
networkingMode=mirrored  # Или NAT
dnsTunneling=true
autoProxy=true
firewall=true
```

Параметры:
- `memory`: Ограничение памяти для WSL2
- `processors`: Количество процессоров
- `localhostForwarding`: Включает перенаправление localhost
- `networkingMode`: Режим сети (mirrored - рекомендуемый для Windows 11)
- `dnsTunneling`: Улучшает разрешение DNS и совместимость с VPN
- `autoProxy`: Автоматически использует настройки прокси Windows в WSL2
- `firewall`: Интеграция с брандмауэром Windows

> **Важно о режимах сети**: Zakenak поддерживает оба режима сети WSL2 - `mirrored` и `NAT`.
> - Режим `mirrored` (рекомендуемый для Windows 11) обеспечивает лучшую интеграцию между Windows и WSL2.
> - Режим `NAT` (по умолчанию) может быть предпочтительнее в некоторых сценариях, особенно при проблемах с доступом к API Kubernetes на порту 6443.
> - Zakenak автоматически определяет используемый режим и настраивает DNS соответствующим образом.

После изменения конфигурации перезапустите WSL:

```powershell
# PowerShell (от имени администратора)
wsl --shutdown
wsl
```

### Определение IP-адресов

#### Получение IP-адреса WSL2 из Windows

Для получения IP-адреса WSL2 из Windows используйте команду:

```powershell
# PowerShell
wsl -d <ИмяДистрибутива> hostname -i
```

Если используется дистрибутив по умолчанию, можно опустить параметр `-d <ИмяДистрибутива>`.

#### Получение IP-адреса Windows из WSL2

Для получения IP-адреса Windows из WSL2 используйте команду:

```bash
# В WSL2
ip route show | grep -i default | awk '{ print $3}'
```

> **Примечание**: В режиме `mirrored` вы можете использовать `localhost` (127.0.0.1) для доступа к сервисам Windows из WSL2 и наоборот, без необходимости знать IP-адреса.

### Настройка брандмауэра для WSL2

В Windows 11 22H2 и выше с WSL 2.0.9 и выше функция брандмауэра Hyper-V включена по умолчанию. Для настройки брандмауэра и разрешения входящих подключений выполните следующую команду в PowerShell от имени администратора:

```powershell
# Разрешить все входящие подключения для WSL2
Set-NetFirewallHyperVVMSetting -Name '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -DefaultInboundAction Allow

# Или разрешить только определенный порт
New-NetFirewallHyperVRule -Name "MyWebServer" -DisplayName "My Web Server" -Direction Inbound -VMCreatorId '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -Protocol TCP -LocalPorts 80
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

### Проброс портов и доступ к WSL2 из локальной сети

#### Базовый проброс портов

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

#### Доступ к WSL2 из локальной сети (LAN)

В режиме NAT (по умолчанию) WSL2 не доступен напрямую из локальной сети. Для обеспечения доступа к сервисам WSL2 из локальной сети необходимо настроить проброс портов на хост-машине Windows.

1. Получите IP-адрес WSL2:
   ```powershell
   # PowerShell
   $wslIp = (wsl hostname -I).Trim()
   echo $wslIp
   ```

2. Настройте проброс портов с помощью команды `netsh`:
   ```powershell
   # PowerShell (от имени администратора)
   netsh interface portproxy add v4tov4 listenport=<ПортНаWindows> listenaddress=0.0.0.0 connectport=<ПортВWSL> connectaddress=$wslIp
   ```

   Например, для проброса порта 3000:
   ```powershell
   netsh interface portproxy add v4tov4 listenport=3000 listenaddress=0.0.0.0 connectport=3000 connectaddress=172.22.53.2
   ```

3. Разрешите входящие подключения в брандмауэре Windows:
   ```powershell
   # PowerShell (от имени администратора)
   New-NetFirewallRule -DisplayName "WSL2 Port 3000" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3000
   ```

4. Убедитесь, что ваше приложение в WSL2 привязано к адресу `0.0.0.0`, а не только к `127.0.0.1`:
   ```bash
   # Пример для Python с Flask
   app.run(host='0.0.0.0', port=3000)
   
   # Пример для Node.js
   app.listen(3000, '0.0.0.0', () => {
     console.log('Server running on port 3000');
   });
   ```

> **Примечание**: В режиме `mirrored` (Windows 11 22H2 и выше) WSL2 может быть доступен напрямую из локальной сети без дополнительной настройки проброса портов, если правильно настроен брандмауэр Hyper-V.

#### Проверка настроек проброса портов

Для просмотра текущих настроек проброса портов выполните:

```powershell
# PowerShell
netsh interface portproxy show all
```

Для удаления проброса порта:

```powershell
# PowerShell (от имени администратора)
netsh interface portproxy delete v4tov4 listenport=<ПортНаWindows> listenaddress=0.0.0.0
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

## DNS в Kubernetes с разными режимами сети WSL2

При работе с Kubernetes в WSL2, важно учитывать особенности DNS-резолвинга в зависимости от выбранного режима сети WSL2 (`mirrored` или `NAT`) и настроек DNS Tunneling.

### Особенности режимов сети WSL2

#### Режим NAT (по умолчанию)
В режиме NAT:
- WSL2 использует виртуальный сетевой адаптер с NAT для связи с хост-системой Windows
- Localhost (127.0.0.1) в WSL2 относится только к самой WSL2
- Для доступа к сервисам WSL2 из Windows используется IP-адрес WSL2
- DNS-запросы проходят через сетевой стек WSL2

#### Режим Mirrored (Windows 11 22H2 и выше)
В режиме Mirrored:
- Сеть "зеркалируется" между Windows и WSL2
- Localhost (127.0.0.1) в WSL2 может ссылаться на сервисы как в WSL2, так и в Windows
- Порты, открытые в WSL2, автоматически доступны в Windows и наоборот
- Улучшенная поддержка IPv6
- Лучшая совместимость с VPN

### DNS Tunneling

В Windows 11 22H2 и выше доступна функция DNS Tunneling, которая значительно улучшает работу DNS в WSL2:

- При включенном DNS Tunneling (`dnsTunneling=true` в `.wslconfig`), WSL использует механизм виртуализации для ответа на DNS-запросы внутри WSL2, вместо отправки их через сетевой пакет
- Это улучшает совместимость с VPN и другими сложными сетевыми конфигурациями
- Снижает задержки при разрешении DNS-имен
- Обеспечивает более стабильную работу DNS в условиях нестабильного сетевого подключения

Для включения DNS Tunneling добавьте следующую настройку в файл `.wslconfig`:

```ini
[wsl2]
dnsTunneling=true
```

### DNS-резолвинг в Kubernetes подах

При работе с Kubernetes в WSL2, поды внутри кластера должны корректно разрешать DNS-имена независимо от режима сети WSL2. Для этого в Zakenak реализован следующий подход:

1. **Автоматическое определение режима сети**:
   ```bash
   # Определение режима сети из файла .wslconfig
   network_mode=$(detect_wsl_network_mode)
   ```

2. **Динамическое определение IP-адреса для DNS**:
   - В режиме NAT без DNS Tunneling: используется 127.0.0.1
   - В режиме NAT с DNS Tunneling: используется IP-адрес хоста Windows (из /etc/resolv.conf)
   - В режиме Mirrored: используется IP-адрес хоста Windows (из /etc/resolv.conf)

3. **Настройка CoreDNS**:
   - Для доменов в зоне prod.local используется полученный IP-адрес
   - Добавлен forward для запросов, которые не разрешаются через hosts
   - При включенном DNS Tunneling, CoreDNS настраивается для использования DNS-сервера Windows

### Пример конфигурации CoreDNS

```yaml
prod.local {
    hosts {
      192.168.1.100 ollama.prod.local  # IP динамически определяется
      192.168.1.100 webui.prod.local
      192.168.1.100 dashboard.prod.local
      fallthrough
    }
    forward . 192.168.1.100  # Перенаправление на хост
}
```

### Проверка DNS-резолвинга в подах

Для проверки корректности DNS-резолвинга в подах можно использовать:

```bash
# Создание тестового пода
kubectl run -it --rm --restart=Never --image=busybox:1.28 dns-test -- nslookup ollama.prod.local

# Проверка доступа к сервису
kubectl run -it --rm --restart=Never --image=curlimages/curl curl-test -- curl -v http://ollama.prod.local:11434/api/version
```

### Рекомендации по настройке DNS в WSL2 для Kubernetes

1. **Для наилучшей совместимости**:
   - Используйте режим Mirrored (`networkingMode=mirrored`)
   - Включите DNS Tunneling (`dnsTunneling=true`)
   - Включите Auto Proxy, если используете прокси (`autoProxy=true`)

2. **Для решения проблем с DNS**:
   - Проверьте содержимое файла `/etc/resolv.conf` в WSL2
   - Убедитесь, что CoreDNS в Kubernetes настроен правильно
   - При использовании VPN, убедитесь, что DNS Tunneling включен

3. **Для отладки DNS-запросов**:
   ```bash
   # Проверка DNS-резолвинга в WSL2
   nslookup example.com
   
   # Проверка DNS-резолвинга в поде Kubernetes
   kubectl run -it --rm --restart=Never --image=busybox:1.28 dns-debug -- nslookup example.com
   
   # Проверка содержимого /etc/resolv.conf в поде
   kubectl run -it --rm --restart=Never --image=busybox:1.28 resolv-debug -- cat /etc/resolv.conf
   ```

Эта конфигурация обеспечивает корректную работу DNS-резолвинга в Kubernetes подах независимо от выбранного режима сети WSL2 и настроек DNS Tunneling.

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

### Проблема: Не работает режим Mirrored

**Решение:**

1. Убедитесь, что у вас Windows 11 22H2 или выше:
   ```powershell
   # PowerShell
   winver
   ```

2. Проверьте настройки в файле `.wslconfig`:
   ```powershell
   # PowerShell
   notepad "$env:USERPROFILE\.wslconfig"
   ```
   
   Убедитесь, что в файле есть строка:
   ```ini
   [wsl2]
   networkingMode=mirrored
   ```

3. Перезапустите WSL:
   ```powershell
   # PowerShell (от имени администратора)
   wsl --shutdown
   wsl
   ```

4. Проверьте, что режим Mirrored работает:
   ```bash
   # В WSL2
   curl localhost:80  # Предполагается, что на Windows запущен веб-сервер на порту 80
   ```

### Проблема: Не работает DNS Tunneling

**Решение:**

1. Проверьте настройки в файле `.wslconfig`:
   ```powershell
   # PowerShell
   notepad "$env:USERPROFILE\.wslconfig"
   ```
   
   Убедитесь, что в файле есть строка:
   ```ini
   [wsl2]
   dnsTunneling=true
   ```

2. Перезапустите WSL:
   ```powershell
   # PowerShell (от имени администратора)
   wsl --shutdown
   wsl
   ```

3. Проверьте содержимое файла `/etc/resolv.conf` в WSL2:
   ```bash
   # В WSL2
   cat /etc/resolv.conf
   ```

4. Проверьте разрешение DNS:
   ```bash
   # В WSL2
   nslookup example.com
   ```

### Проблема: Не работает доступ к WSL2 из локальной сети

**Решение:**

1. Если вы используете режим NAT (по умолчанию):
   - Проверьте настройки проброса портов:
     ```powershell
     # PowerShell
     netsh interface portproxy show all
     ```
   - Убедитесь, что брандмауэр разрешает входящие подключения:
     ```powershell
     # PowerShell (от имени администратора)
     Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*WSL*" }
     ```

2. Если вы используете режим Mirrored:
   - Настройте брандмауэр Hyper-V:
     ```powershell
     # PowerShell (от имени администратора)
     Set-NetFirewallHyperVVMSetting -Name '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -DefaultInboundAction Allow
     ```
   - Или создайте правило для конкретного порта:
     ```powershell
     # PowerShell (от имени администратора)
     New-NetFirewallHyperVRule -Name "MyWebServer" -DisplayName "My Web Server" -Direction Inbound -VMCreatorId '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -Protocol TCP -LocalPorts 80
     ```

3. Убедитесь, что ваше приложение в WSL2 привязано к адресу `0.0.0.0`, а не только к `127.0.0.1`

### Проблема: Проблемы с сетью при использовании VPN

**Решение:**

1. Включите DNS Tunneling и режим Mirrored в файле `.wslconfig`:
   ```ini
   [wsl2]
   networkingMode=mirrored
   dnsTunneling=true
   ```

2. Перезапустите WSL:
   ```powershell
   # PowerShell (от имени администратора)
   wsl --shutdown
   wsl
   ```

3. Если проблемы с DNS сохраняются, настройте статический DNS в WSL2:
   ```bash
   # В WSL2
   sudo rm /etc/resolv.conf
   sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
   sudo bash -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf'
   sudo bash -c 'echo "[network]" > /etc/wsl.conf'
   sudo bash -c 'echo "generateResolvConf = false" >> /etc/wsl.conf'
   ```

4. Если вы используете Kubernetes в WSL2, перезапустите CoreDNS:
   ```bash
   # В WSL2
   kubectl -n kube-system rollout restart deployment coredns
   ```