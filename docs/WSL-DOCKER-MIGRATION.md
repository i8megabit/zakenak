# Миграция и настройка WSL и Docker

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
  - [Устранение неполадок](troubleshooting.md)
  - [GPU в WSL2](GPU-WSL.md)
  - [Использование Docker](DOCKER-USAGE.md)
  - [Настройка KUBECONFIG](KUBECONFIG.md)
  - [Мониторинг](MONITORING.md)
  - [Настройка сети](NETWORK-CONFIGURATION.md)
  - [Миграция и настройка WSL и Docker](WSL-DOCKER-MIGRATION.md) (текущий документ)
- [Примеры](../examples/README.md)

## Содержание
1. [Введение](#введение)
2. [Миграция WSL](#миграция-wsl)
   - [Экспорт существующего дистрибутива](#экспорт-существующего-дистрибутива)
   - [Импорт дистрибутива на новую машину](#импорт-дистрибутива-на-новую-машину)
   - [Перенос WSL на другой диск](#перенос-wsl-на-другой-диск)
3. [Монтирование дисков в WSL](#монтирование-дисков-в-wsl)
   - [Автоматическое монтирование при запуске](#автоматическое-монтирование-при-запуске)
   - [Монтирование сетевых дисков](#монтирование-сетевых-дисков)
   - [Настройка прав доступа](#настройка-прав-доступа)
4. [Настройка Docker в WSL](#настройка-docker-в-wsl)
   - [Установка Docker Engine в WSL](#установка-docker-engine-в-wsl)
   - [Настройка Docker для работы с GPU](#настройка-docker-для-работы-с-gpu)
   - [Перенос образов и контейнеров Docker](#перенос-образов-и-контейнеров-docker)
5. [Оптимизация производительности](#оптимизация-производительности)
   - [Настройка памяти и CPU](#настройка-памяти-и-cpu)
   - [Оптимизация файловой системы](#оптимизация-файловой-системы)
   - [Ускорение запуска WSL](#ускорение-запуска-wsl)
6. [Устранение неполадок](#устранение-неполадок)

## Введение

Данное руководство описывает процессы миграции, настройки и оптимизации Windows Subsystem for Linux (WSL) и Docker для использования в проекте Zakenak. Эти инструкции помогут вам перенести существующую среду WSL на новую машину, настроить монтирование дисков и оптимизировать работу Docker.

## Миграция WSL

### Экспорт существующего дистрибутива

Для переноса WSL на другую машину или диск, сначала необходимо экспортировать существующий дистрибутив:

```bash
# Просмотр списка установленных дистрибутивов
wsl --list --verbose

# Остановка дистрибутива перед экспортом
wsl --terminate <ИМЯ_ДИСТРИБУТИВА>

# Экспорт дистрибутива в tar-файл
wsl --export <ИМЯ_ДИСТРИБУТИВА> <ПУТЬ_К_ФАЙЛУ.tar>
```

Например:
```bash
wsl --terminate Ubuntu-22.04
wsl --export Ubuntu-22.04 D:\WSL-Backup\ubuntu-22.04-backup.tar
```

### Импорт дистрибутива на новую машину

После экспорта вы можете импортировать дистрибутив на новую машину:

```bash
# Создание директории для нового дистрибутива
mkdir <ПУТЬ_К_ДИРЕКТОРИИ_УСТАНОВКИ>

# Импорт дистрибутива из tar-файла
wsl --import <ИМЯ_НОВОГО_ДИСТРИБУТИВА> <ПУТЬ_К_ДИРЕКТОРИИ_УСТАНОВКИ> <ПУТЬ_К_ФАЙЛУ.tar>
```

Например:
```bash
mkdir D:\WSL\Ubuntu-22.04
wsl --import Ubuntu-22.04 D:\WSL\Ubuntu-22.04 D:\WSL-Backup\ubuntu-22.04-backup.tar
```

### Перенос WSL на другой диск

Для переноса WSL на другой диск выполните следующие шаги:

1. Экспортируйте существующий дистрибутив:
```bash
wsl --terminate <ИМЯ_ДИСТРИБУТИВА>
wsl --export <ИМЯ_ДИСТРИБУТИВА> <ПУТЬ_К_ФАЙЛУ.tar>
```

2. Удалите существующий дистрибутив (только после успешного экспорта):
```bash
wsl --unregister <ИМЯ_ДИСТРИБУТИВА>
```

3. Импортируйте дистрибутив на новый диск:
```bash
mkdir <НОВЫЙ_ПУТЬ_К_ДИРЕКТОРИИ>
wsl --import <ИМЯ_ДИСТРИБУТИВА> <НОВЫЙ_ПУТЬ_К_ДИРЕКТОРИИ> <ПУТЬ_К_ФАЙЛУ.tar>
```

4. Проверьте, что дистрибутив успешно импортирован:
```bash
wsl --list --verbose
```

## Монтирование дисков в WSL

### Автоматическое монтирование при запуске

Для автоматического монтирования дисков при запуске WSL, добавьте соответствующие команды в файл `/etc/wsl.conf`:

```bash
# Создание или редактирование файла wsl.conf
sudo nano /etc/wsl.conf
```

Добавьте следующие настройки:
```ini
[automount]
enabled = true
options = "metadata,umask=22,fmask=11"
mountFsTab = true

[boot]
command = mount -a
```

Для монтирования дополнительных дисков, отредактируйте файл `/etc/fstab`:
```bash
sudo nano /etc/fstab
```

Добавьте строки для монтирования дисков:
```
# Монтирование локального диска
/dev/sdX /mnt/mydisk ext4 defaults 0 0

# Монтирование Windows диска
\\wsl$\<ИМЯ_ДИСТРИБУТИВА>\mnt\d /mnt/d drvfs defaults 0 0
```

### Монтирование сетевых дисков

Для монтирования сетевых дисков в WSL:

1. Установите необходимые пакеты:
```bash
sudo apt update
sudo apt install -y cifs-utils
```

2. Создайте точку монтирования:
```bash
sudo mkdir -p /mnt/network-share
```

3. Монтирование сетевого диска:
```bash
sudo mount -t cifs //server/share /mnt/network-share -o username=user,password=pass,uid=$(id -u),gid=$(id -g)
```

4. Для автоматического монтирования при запуске, добавьте в `/etc/fstab`:
```
//server/share /mnt/network-share cifs username=user,password=pass,uid=1000,gid=1000 0 0
```

### Настройка прав доступа

Для корректной работы с файлами в WSL важно настроить правильные права доступа:

1. Настройка прав для монтированных Windows дисков:
```bash
# В файле /etc/wsl.conf
[automount]
options = "metadata,umask=22,fmask=11,uid=1000,gid=1000"
```

2. Настройка прав для конкретной точки монтирования:
```bash
sudo mount -t drvfs D: /mnt/d -o metadata,uid=1000,gid=1000,umask=22,fmask=11
```

## Настройка Docker в WSL

### Установка Docker Engine в WSL

Для установки Docker непосредственно в WSL (без Docker Desktop):

1. Обновите пакеты и установите необходимые зависимости:
```bash
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
```

2. Добавьте официальный GPG ключ Docker:
```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

3. Добавьте репозиторий Docker:
```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

4. Установите Docker Engine:
```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
```

5. Добавьте текущего пользователя в группу docker:
```bash
sudo usermod -aG docker $USER
```

6. Настройте автозапуск Docker при старте WSL:
```bash
# В файле /etc/wsl.conf
[boot]
command = service docker start
```

### Настройка Docker для работы с GPU

Для использования GPU в Docker внутри WSL:

1. Установите NVIDIA Container Toolkit:
```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
```

2. Настройте Docker для использования NVIDIA Container Runtime:
```bash
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

3. Проверьте настройку:
```bash
docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu22.04 nvidia-smi
```

### Перенос образов и контейнеров Docker

Для переноса образов Docker между системами:

1. Сохранение образов в tar-файлы:
```bash
# Сохранение одного образа
docker save -o <имя_файла.tar> <имя_образа>:<тег>

# Сохранение нескольких образов
docker save -o images.tar image1:tag1 image2:tag2
```

2. Перенос tar-файлов на новую систему

3. Загрузка образов из tar-файлов:
```bash
docker load -i <имя_файла.tar>
```

4. Для переноса контейнеров рекомендуется использовать Docker Compose:
```bash
# Экспорт конфигурации в docker-compose.yml
docker-compose config > docker-compose.yml

# Перенос файла на новую систему

# Запуск контейнеров на новой системе
docker-compose up -d
```

## Оптимизация производительности

### Настройка памяти и CPU

Для оптимизации использования ресурсов WSL, создайте или отредактируйте файл `.wslconfig` в домашней директории Windows (`%USERPROFILE%`):

```ini
[wsl2]
memory=8GB
processors=4
swap=4GB
localhostForwarding=true
kernelCommandLine = cgroup_no_v1=all cgroup_enable=memory swapaccount=1
```

Эти настройки:
- Ограничивают использование памяти до 8GB
- Ограничивают использование процессоров до 4 ядер
- Устанавливают размер файла подкачки в 4GB
- Включают перенаправление localhost
- Настраивают параметры ядра для поддержки cgroup v2 и Docker

### Оптимизация файловой системы

Для улучшения производительности файловой системы:

1. Используйте нативную файловую систему Linux для проектов:
```bash
# Создание проектов в домашней директории WSL вместо монтированных Windows дисков
mkdir -p ~/projects
```

2. Настройте кэширование для монтированных дисков:
```bash
# В файле /etc/wsl.conf
[automount]
options = "metadata,cache=strict,uid=1000,gid=1000"
```

3. Используйте WSL для операций с файлами вместо Windows Explorer:
```bash
# Пример: копирование файлов внутри WSL вместо Windows
cp -r /mnt/c/source ~/projects/destination
```

### Ускорение запуска WSL

Для ускорения запуска WSL:

1. Настройте автоматический запуск WSL при старте Windows:
```powershell
# В PowerShell с правами администратора
wsl --set-default-version 2
wsl --set-default <ИМЯ_ДИСТРИБУТИВА>
```

2. Создайте задачу в планировщике задач Windows для запуска WSL при старте системы:
```powershell
# Создание bat-файла для запуска WSL
echo wsl -d <ИМЯ_ДИСТРИБУТИВА> -e sleep 1 > %USERPROFILE%\wsl-startup.bat

# Затем создайте задачу в планировщике задач, которая запускает этот bat-файл при входе в систему
```

## Устранение неполадок

### Проблема: WSL не запускается

1. Проверьте статус WSL:
```powershell
wsl --status
```

2. Перезапустите службу WSL:
```powershell
wsl --shutdown
```

3. Проверьте журналы событий Windows для ошибок WSL

### Проблема: Ошибки монтирования дисков

1. Проверьте настройки монтирования:
```bash
cat /etc/wsl.conf
```

2. Проверьте права доступа:
```bash
ls -la /mnt/
```

3. Попробуйте монтировать вручную:
```bash
sudo mount -t drvfs D: /mnt/d -o metadata
```

### Проблема: Docker не работает с GPU

1. Проверьте установку NVIDIA Container Toolkit:
```bash
dpkg -l | grep nvidia-container-toolkit
```

2. Проверьте конфигурацию Docker:
```bash
cat /etc/docker/daemon.json
```

3. Перезапустите Docker:
```bash
sudo systemctl restart docker
```

4. Проверьте доступность GPU:
```bash
nvidia-smi
docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu22.04 nvidia-smi
```

```plain text
Copyright (c) 2025 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. 
See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT.
```