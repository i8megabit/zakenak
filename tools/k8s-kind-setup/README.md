# Kubernetes Kind Setup

## Версия
1.0.1

## Описание
Инструменты для настройки локального Kubernetes кластера с использованием Kind.

## Структура
```
.
├── manifests/
│   ├── coredns-custom-config.yaml
│   └── coredns-patch.yaml
├── setup-dns.sh
└── README.md
```

## Использование

### Настройка DNS
```bash
./setup-dns.sh
```

### Проверка DNS
```bash
kubectl run -i --rm --restart=Never busybox --image=busybox:1.28 -- nslookup webui.prod.local
kubectl run -i --rm --restart=Never busybox --image=busybox:1.28 -- nslookup ollama.prod.local
```

## Конфигурация
- Файлы конфигурации DNS находятся в директории `manifests/`
- Для изменения DNS записей редактируйте файлы:
	- `manifests/coredns-custom-config.yaml`
	- `manifests/coredns-patch.yaml`
```