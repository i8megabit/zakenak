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
## [1.0.3] - 2025-02-25

### Changed
- Обновлена интеграция с GPU:
  - Удалена локальная конфигурация NVIDIA device plugin
  - Добавлена поддержка централизованного управления GPU
  - Оптимизирована работа с Ollama через GPU
- Улучшена производительность:
  - Настроены параметры для работы с большими моделями
  - Оптимизировано использование GPU памяти
  - Улучшена обработка параллельных запросов

### Fixed
- Исправлена интеграция с WSL2 GPU
- Оптимизированы настройки для работы с deepseek-r1:32b с 4-битной квантизацией (q4_0)

## [1.0.2] -  2025-02-13

### Added
- Добавлен Service для обеспечения доступа к Open WebUI
- Настроена интеграция с Ingress-контроллером

### Fixed
- Исправлена проблема с отсутствием endpoints

## [1.0.1] -  2025-02-13

### Fixed
- Исправлены отступы в deployment.yaml для устранения предупреждения "unknown field spec"
- Оптимизирована структура YAML файла для лучшей читаемости
- Исправлено форматирование списков в deployment.yaml

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