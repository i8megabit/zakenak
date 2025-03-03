# Оптимизация настроек для модели deepseek-r1:14b-qwen-distill-q4_K_M

Данный документ описывает оптимизированные настройки и процесс установки модели deepseek-r1:14b-qwen-distill-q4_K_M для использования с Ollama в Docker Compose.

## Оптимизированные настройки

В файле `docker-compose/docker-compose.yaml` настроены следующие оптимизированные параметры для модели:

```yaml
environment:
  - OLLAMA_HOST=0.0.0.0
  - OLLAMA_COMPUTE_TYPE=gpu
  - OLLAMA_GPU_LAYERS=99
  - OLLAMA_F16=true
  - OLLAMA_QUANTIZATION=q4_K_M
  - OLLAMA_CUDA_MEMORY_FRACTION=0.95
  - OLLAMA_CUDA_FORCE_ALLOCATION=true
  - OLLAMA_MODEL=deepseek-r1:14b-qwen-distill-q4_K_M
  - OLLAMA_CONTEXT_SIZE=8192
```

Эти настройки обеспечивают:
- Использование GPU для максимальной производительности
- Загрузку всех слоев модели на GPU (99 слоев)
- Использование 16-битной точности (F16) для вычислений
- Правильную квантизацию (q4_K_M) для данной модели
- Оптимальное использование памяти GPU (95%)
- Принудительное выделение памяти CUDA для стабильной работы
- Автоматическую загрузку модели при запуске
- Оптимальный размер контекстного окна (8192 токенов)

## Процесс установки

Для оптимальной работы модели рекомендуется следующий процесс установки:

1. Скачайте модель через Windows-приложение Ollama
2. Скопируйте файлы модели в примонтированный к Docker-контейнеру каталог `/mnt/o`
3. Установите права доступа к файлам модели на `root:root`
4. Запустите Ollama через Docker Compose с оптимизированными настройками

Для автоматизации этого процесса можно использовать скрипт `setup-deepseek-model.sh`:

```bash
./setup-deepseek-model.sh
```

## Ручная установка

Если вы предпочитаете установить модель вручную:

1. Скачайте модель через Windows-приложение Ollama
2. Скопируйте файлы модели в каталог `/mnt/o/models/`
3. Установите права доступа:
   ```bash
   sudo chown -R root:root /mnt/o/models
   sudo chmod -R 755 /mnt/o/models
   ```
4. Запустите Ollama через Docker Compose:
   ```bash
   cd docker-compose
   docker compose up -d
   ```

## Проверка работоспособности

Чтобы проверить, что модель успешно загружена и работает:

```bash
curl -X POST http://localhost:11434/api/generate -d '{"model":"deepseek-r1:14b-qwen-distill-q4_K_M","prompt":"Привет, как дела?"}'
```

## Устранение неполадок

Если возникают проблемы с запуском модели:

1. Проверьте логи контейнера:
   ```bash
   docker logs ollama
   ```

2. Убедитесь, что модель доступна в Ollama:
   ```bash
   curl http://localhost:11434/api/tags
   ```

3. Проверьте, что каталог `/mnt/o` правильно примонтирован к контейнеру:
   ```bash
   docker inspect ollama | grep -A 10 Mounts
   ```

4. Убедитесь, что у файлов модели правильные права доступа:
   ```bash
   ls -la /mnt/o/models
   ```