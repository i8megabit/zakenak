# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# 
# This file is part of Ƶakenak™® project.
# https://github.com/i8megabit/zakenak
#
# This program is free software and is released under the terms of the MIT License.
# See LICENSE.md file in the project root for full license information.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#
# TRADEMARK NOTICE:
# Ƶakenak™® and the Ƶakenak logo are registered trademarks of Mikhail Eberil.
# All rights reserved. The Ƶakenak trademark and brand may not be used in any way 
# without express written permission from the trademark owner.


# Helm Setup Tool
```ascii
     ______     _                      _    
    |___  /    | |                    | |   
       / / __ _| |  _ _   ___     ___ | |  _
      / / / _` | |/ / _`||  _ \ / _` || |/ /
     / /_| (_| |  < by_Eberil| | (_| ||   < 
    /_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\
  
    Should Harbour?	No.

Версия: 1.0.0

Инструмент для автоматической установки и настройки Helm в Linux-системах.

## Описание
Скрипт автоматизирует процесс установки Helm, добавляет популярные репозитории и проверяет корректность установки.

## Возможности
- Автоматическая установка Helm
- Добавление популярных репозиториев:
    - Jetstack (cert-manager)
    - Bitnami
    - Prometheus Community
    - Ingress Nginx
- Проверка корректности установки
- Вывод информации о версии и репозиториях

## Требования
- Linux-система (Ubuntu/Debian)
- Права sudo
- Доступ к интернету

## Установка и использование
1. Сделайте скрипт исполняемым:
```bash
chmod +x install-helm.sh
```

2. Запустите скрипт:
```bash
./install-helm.sh
```

## Проверка установки
После установки можно проверить работу Helm:
```bash
helm version
helm repo list
```

## Устранение неполадок
### Ошибка доступа
Если возникает ошибка доступа, убедитесь что скрипт запущен с правами sudo:
```bash
sudo ./install-helm.sh
```

### Проблемы с репозиториями
Если репозитории недоступны, проверьте подключение к интернету и выполните:
```bash
helm repo update
```