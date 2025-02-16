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
- Базовая структура чарта для cert-manager
- Интеграция с локальным CA
- Автоматическая генерация сертификатов
- Настройка ClusterIssuer
- Поддержка самоподписанных сертификатов
- Конфигурация RBAC

### Changed
- Оптимизированы настройки cert-manager
- Улучшена конфигурация CRDs
- Добавлены проверки готовности
- Настроена интеграция с Ingress

### Fixed
- Исправлены проблемы с установкой CRDs
- Улучшена обработка ошибок
- Оптимизирована последовательность установки

```plain text
Copyright (c) 2024 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

The name "Zakenak" and associated branding are trademarks of @eberil and may not be used without express written permission.
```