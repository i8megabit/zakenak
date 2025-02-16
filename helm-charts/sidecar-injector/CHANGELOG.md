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
## [0.1.0] - 2024-02-13

### Added
- Создана базовая структура чарта
- Реализована поддержка входящих и исходящих TLS сайдкаров
- Добавлена интеграция с cert-manager
- Настраиваемые конфигурации Nginx
- Реализованы RBAC и ServiceAccount
- Добавлена поддержка автоматической генерации сертификатов
- Реализована конфигурация через values.yaml

### Changed
- Оптимизированы настройки сайдкаров
- Улучшена конфигурация TLS
- Добавлены проверки готовности
- Улучшена документация

### Fixed
- Исправлены проблемы с инжекцией сайдкаров
- Улучшена обработка ошибок
- Оптимизирована работа с сертификатами
- Исправлены проблемы с путями монтирования

```plain text
Copyright (c) 2024 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

The name "Zakenak" and associated branding are trademarks of @eberil and may not be used without express written permission.
```