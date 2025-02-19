# Charts Management Tool

## Версия: 1.2.0

## Описание
Инструмент для управления Helm чартами в кластере Kubernetes. Поддерживает установку, обновление и удаление чартов с гибкой конфигурацией.

## Требования
- Kubernetes кластер
- Helm 3.x
- kubectl
- bash 4.x или выше

## Установка
Инструмент является частью k8s-kind-setup и не требует отдельной установки.

## Использование
```bash
./src/charts.sh [опции] <действие> <чарт>

Действия:
	install         - Установить чарт
	upgrade         - Обновить чарт
	uninstall       - Удалить чарт
	list            - Показать список установленных чартов

Опции:
	-n, --namespace <namespace>  - Использовать указанный namespace
	-v, --version <version>      - Использовать указанную версию
	-f, --values <file>         - Использовать дополнительный values файл
	-h, --help                  - Показать справку
```

## Примеры
```bash
# Установка чарта
./src/charts.sh install ollama

# Установка чарта с указанием namespace
./src/charts.sh -n custom-namespace install open-webui

# Обновление чарта с дополнительными values
./src/charts.sh -f custom-values.yaml upgrade ollama
```

## Поддерживаемые чарты
- ollama
- open-webui