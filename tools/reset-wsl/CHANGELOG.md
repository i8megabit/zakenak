# CHANGELOG

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

```plain text
Copyright (c) 2023-2025 Mikhail Eberil (@eberil)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```