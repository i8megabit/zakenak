# WSL Setup Tool для Kubernetes Kind

## Версия
1.0.0

## Описание
Инструмент для автоматизированной настройки WSL2 окружения с поддержкой NVIDIA GPU для работы с Kubernetes Kind кластером.

## Особенности
- 🚀 Автоматическая настройка WSL2
- 🎮 Установка CUDA и настройка NVIDIA Container Toolkit
- 🔧 Оптимизация системных параметров
- 📊 Проверка системных требований
- 🛡️ Безопасная конфигурация

## Системные требования
- Windows 11 с WSL2
- Ubuntu 22.04 LTS
- NVIDIA GPU (Compute Capability 7.0+)
- Минимум 16GB RAM
- NVIDIA Driver 535.104.05+
- Docker Desktop с WSL2 интеграцией

## Использование
```bash
./setup-wsl.sh
```

## Проверка установки
После установки выполните следующие команды для проверки:
```bash
# Проверка NVIDIA драйвера
nvidia-smi

# Проверка NVIDIA Container Toolkit
docker run --rm --gpus all nvidia/cuda:12.6.1-base-ubuntu22.04 nvidia-smi
```

## Конфигурация
| Параметр | Описание | По умолчанию |
|----------|----------|--------------|
| `CUDA_VERSION` | Версия CUDA | `12.6.1` |
| `REQUIRED_MEMORY` | Минимальный объем RAM (GB) | `16` |
| `WSL_DISTRO` | Дистрибутив WSL | `Ubuntu-22.04` |

## Структура
```
.
├── src/                # Исходный код
│   ├── setup-wsl.sh   # Основной скрипт настройки
│   └── cuda.sh        # Скрипт установки CUDA
├── tests/             # Тестовые файлы
├── CHANGELOG.md       # История изменений
└── README.md         # Документация
```

## Документация
Подробная документация по работе с GPU и тензорными операциями доступна в [GPU-WSL.md](/docs/GPU-WSL.md).

## Поддержка
- Email: i8megabit@gmail.com
- GitHub Issues: [Создать issue](https://github.com/i8megabit/zakenak/issues)