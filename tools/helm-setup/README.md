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

```plain text
Copyright (c)  2025 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

The name "Zakenak" and associated branding are trademarks of @eberil and may not be used without express written permission.
```