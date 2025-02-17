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


# Changelog

```ascii
     ______     _                      _    
    |___  /    | |                    | |   
       / / __ _| |  _ _   ___     ___ | |  _
      / / / _` | |/ / _`||  _ \ / _` || |/ /
     / /_| (_| |  < by_Eberil| | (_| ||   < 
    /_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\
  
    Should Harbour?	No.

## [1.1.0] -  2025-01-XX

### Added
- Добавлена автоматическая генерация самоподписанных TLS-сертификатов
- Добавлено создание TLS-секретов (ollama-tls и open-webui-tls)
- Добавлена поддержка HTTPS в ingress-nginx

### Fixed
- Исправлена проблема с невалидным контейнером init-ollama-dir
- Исправлена проблема с отсутствующими TLS-секретами

## [1.0.1] -  2025-02-13

### Added
- Создана структура директорий для манифестов DNS
- Добавлен файл конфигурации CoreDNS (coredns-custom-config.yaml)
- Добавлен файл патча CoreDNS (coredns-patch.yaml)
- Улучшен скрипт setup-dns.sh с проверкой наличия директории manifests

### Fixed
- Исправлена проблема с отсутствующими файлами конфигурации DNS
- Оптимизирована конфигурация CoreDNS для локальных доменов