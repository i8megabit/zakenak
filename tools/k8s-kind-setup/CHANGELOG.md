# Changelog

## [1.3.2] - 2024-02-19
### Added
- Добавлен скрипт setup-wsl.sh для автоматизации настройки WSL2
- Интеграция с NVIDIA Container Toolkit
- Автоматическая установка CUDA 12.8

### Changed
- Оптимизирована конфигурация WSL2 для работы с GPU
- Улучшена обработка ошибок в скриптах

### Fixed
- Исправлена проверка версии драйвера NVIDIA
- Улучшена совместимость с последними версиями WSL2

## [1.3.1] - 2024-02-01
### Initial Release
- Базовая функциональность Kind кластера
- Поддержка GPU в Kubernetes
- Интеграция с локальным CA

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