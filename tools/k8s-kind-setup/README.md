# Kubernetes Kind Setup

## Версия
1.3.0

## Описание
Инструменты для настройки локального Kubernetes кластера с использованием Kind.

## Структура
```
.
├── manifests/
│   ├── coredns-custom-config.yaml
│   └── coredns-patch.yaml
├── env.sh                # Общие переменные окружения
├── deploy-all.sh        # Полное развертывание кластера
├── manage-charts.sh     # Управление отдельными чартами
├── setup-dns.sh         # Настройка DNS
└── README.md
```

## Использование

### Полное развертывание
```bash
./deploy-all.sh
```

### Управление чартами
```bash
# Установка отдельного чарта
./manage-charts.sh install ollama -n prod -v 0.1.17

# Обновление всех чартов
./manage-charts.sh upgrade all

# Удаление чарта
./manage-charts.sh uninstall open-webui

# Просмотр списка установленных чартов
./manage-charts.sh list
```

### Проверка DNS
```bash
kubectl run -i --rm --restart=Never busybox --image=busybox:1.28 -- nslookup webui.prod.local
kubectl run -i --rm --restart=Never busybox --image=busybox:1.28 -- nslookup ollama.prod.local
```

## Конфигурация
- Файлы конфигурации DNS находятся в директории `manifests/`
- Общие переменные окружения в `env.sh`
- Версии компонентов и пути к чартам настраиваются в `env.sh`
```