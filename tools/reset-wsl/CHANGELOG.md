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


# CHANGELOG
```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

Should Harbour?	No.
```
## [1.2.0] -  2025-01-09
### Added
- Добавлена проверка политики выполнения скриптов в Reset-WSL.ps1
- Добавлены инструкции по обходу ограничений политики выполнения
- Расширена документация с информацией о настройке безопасности

## [1.1.0] -  2025-01-09
### Changed
- Перемещен скрипт Reset-WSL.ps1 в отдельную директорию tools/reset-wsl
- Создана отдельная документация для инструмента Reset-WSL
- Улучшена структура проекта

## [1.0.0] -  2025-01-09
### Added
- Создан скрипт Reset-WSL.ps1 для полного сброса и переустановки WSL
- Скрипт включает в себя:
  - Автоматическое завершение всех процессов WSL
  - Удаление всех существующих дистрибутивов
  - Переустановку компонента Windows Subsystem for Linux
  - Установку WSL2 и Ubuntu по умолчанию