# Скрипт charts.sh

Этот скрипт управляет чартами в каталоге `helm-charts`. Его можно запускать локально или внутри Docker-контейнера.

## Команды

```bash
./charts.sh list                       # показать список чартов
./charts.sh install ЧАРТ [namespace]   # установить чарт
./charts.sh upgrade ЧАРТ [namespace]   # обновить чарт
./charts.sh uninstall ЧАРТ [namespace] # удалить чарт
./charts.sh install-all [namespace]    # установить все чарты по порядку
```

Переменные окружения `CHARTS_DIR` и `ORDER_FILE` позволяют переопределить расположение чартов и файла порядка установки.
