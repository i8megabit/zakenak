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
## [1.1.0] -  2025-02-16

### Added
- Добавлена поддержка GPU через NVIDIA Container Runtime
- Реализована интеграция с WSL2 для доступа к GPU
- Добавлена автоматическая настройка CUDA окружения
- Создана система управления состоянием кластера
- Реализован механизм конвергенции состояния
- Добавлена поддержка GitOps workflow
- Интеграция с container registry
- Добавлены инструменты для мониторинга GPU

### Changed
- Оптимизирована структура проекта
- Улучшена система сборки с поддержкой GPU
- Обновлены конфигурации для работы с NVIDIA драйверами
- Улучшена документация по установке и настройке
- Оптимизированы параметры производительности

### Security
- Добавлена защита торговой марки Zakenak
- Внедрена система лицензирования
- Улучшена безопасность доступа к GPU ресурсам
- Добавлены проверки целостности конфигураций

## [1.0.0] -  2025-02-15

### Added
- Создан базовый функционал Zakenak
- Реализована система конвергенции состояния
- Добавлена поддержка GPU и WSL2
- Интеграция с container registry
- Система управления состоянием
- Поддержка GitOps
- Создана базовая документация
- Добавлен ASCII баннер
- Реализован CLI интерфейс

### Changed
- Оптимизирована архитектура приложения
- Улучшена производительность
- Упрощена конфигурация
- Минимизирован размер бинарного файла

### Security
- Добавлена базовая система безопасности
- Реализована поддержка RBAC
- Безопасное хранение креденшелов
- Проверка целостности конфигураций

## [0.2.0] -  2025-02-14

### Added
- Прототип системы конвергенции
- Базовая поддержка GPU
- Начальная интеграция с WSL2

### Changed
- Реструктуризация кодовой базы
- Улучшение системы логирования
- Оптимизация работы с Docker

## [0.1.0] -  2025-02-13

### Added
- Инициализация проекта
- Базовая структура приложения
- Система сборки
- Начальная документация

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