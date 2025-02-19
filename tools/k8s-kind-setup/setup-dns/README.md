# Setup DNS

## Версия
1.0.0

## Описание
Инструмент для настройки DNS в Kubernetes кластере с поддержкой .prod.local зоны. Обеспечивает корректную работу DNS-резолвинга для внутренних сервисов.

## Требования
- Kubernetes кластер 1.25+
- kubectl настроенный для доступа к кластеру
- CoreDNS (устанавливается автоматически в кластере Kind)

## Установка
```bash
./setup-dns.sh
```

## Функциональность
- Настройка CoreDNS для работы с .prod.local зоной
- Интеграция с Kubernetes Ingress
- Поддержка кастомных DNS записей
- Автоматическая конфигурация DNS для сервисов

## Проверка установки
```bash
# Проверка DNS резолвинга
kubectl run -i --rm --restart=Never busybox --image=busybox:1.28 -- nslookup ollama.prod.local
kubectl run -i --rm --restart=Never busybox --image=busybox:1.28 -- nslookup webui.prod.local
```

## Структура
```
setup-dns/
├── README.md
├── CHANGELOG.md
└── src/
	├── setup-dns.sh
	└── manifests/
		├── coredns-custom-config.yaml
		└── coredns-patch.yaml
```