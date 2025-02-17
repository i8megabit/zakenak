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
```
## [0.1.0] -  2025-02-13

### Added
- Создана базовая структура чарта для локального CA
- Реализована автоматическая генерация корневого CA
- Добавлена поддержка множественных сертификатов
- Интеграция с cert-manager
- Настройка ClusterIssuer
- Автоматическое обновление сертификатов
- Конфигурация через values.yaml
- Поддержка множественных DNS имен
- RBAC для безопасного доступа

### Changed
- Оптимизированы настройки CA
- Улучшена конфигурация сертификатов
- Добавлены проверки валидности
- Настроена автоматическая ротация
- Улучшена документация

### Security
- Реализовано безопасное хранение ключей
- Настроены ограничения доступа
- Добавлена поддержка RBAC
- Изоляция компонентов