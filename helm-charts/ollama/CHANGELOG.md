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
## [0.3.0] - 2025-03-10

### Added
- Добавлена опциональная конфигурация селектора GPU узлов:
  - Новый параметр `deployment.gpuNodeSelector.enabled` для включения/отключения селектора
  - Настраиваемые параметры `deployment.gpuNodeSelector.labelKey` и `deployment.gpuNodeSelector.labelValue`
  - По умолчанию селектор отключен для предотвращения проблем с планированием подов

### Changed
- Улучшена документация по устранению неполадок с селектором узлов
- Обновлена таблица параметров в README.md

### Fixed
- Исправлена проблема с планированием подов на узлах без GPU меток

## [0.2.0] - 2025-02-25

### Changed
- Централизовано управление GPU:
  - Удалена конфигурация NVIDIA device plugin
  - Перенесены настройки GPU в charts.sh
  - Упрощена конфигурация GPU в values.yaml
- Оптимизирована интеграция с WSL2:
  - Обновлены пути монтирования GPU устройств
  - Улучшена совместимость с NVIDIA Container Toolkit
  - Добавлены проверки GPU ресурсов

### Removed
- Удален nvidia-device-plugin.yaml
- Удалены избыточные GPU параметры из values.yaml
- Упрощена конфигурация nvidia-config.yaml

## [0.1.0] -  2025-02-13

### Added
- Базовая структура чарта для Ollama
- Поддержка NVIDIA GPU в WSL2
- Интеграция с cert-manager для TLS
- Настройка сетевых политик
- Конфигурация персистентного хранилища
- Оптимизация для модели deepseek-r1:32b с 4-битной квантизацией

### Changed
- Оптимизированы настройки GPU
- Улучшена конфигурация сетевой безопасности
- Добавлены проверки готовности и живости

### Fixed
- Исправлены проблемы с монтированием GPU устройств
- Оптимизирована работа с памятью
- Улучшена обработка ошибок

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