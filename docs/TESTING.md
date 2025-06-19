# Тестирование Zakenak

Этот файл описывает базовые проверки проекта.

## Запуск тестов

```bash
cd tools/zakenak
go test ./...
```

## Покрываемые модули
- загрузка конфигурации
- менеджер состояния
- настройки сборки
- генерация конфигурации Kind

Тесты не требуют сторонних сервисов и выполняются быстро.

# Coverage

To generate coverage reports, run:
```bash
cd tools/zakenak
make coverage
```
The HTML report is saved to `build/coverage.html`.
