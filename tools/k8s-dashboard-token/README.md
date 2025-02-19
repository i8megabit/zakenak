# Kubernetes Dashboard Token Generator v1.0.0

## Описание
Инструмент для генерации токенов доступа к Kubernetes Dashboard. Поддерживает как новые (>=1.24), так и старые версии Kubernetes.

## Требования
- Установленный и настроенный kubectl
- Доступ к Kubernetes кластеру
- Установленный Kubernetes Dashboard
- Настроенный сервисный аккаунт admin-user

## Установка
Никаких дополнительных действий по установке не требуется. Скрипт использует стандартные утилиты командной строки.

## Использование
```bash
./dashboard-token.sh
```

## Функциональность
- Автоматическое определение версии Kubernetes
- Поддержка различных методов получения токена
- Проверка наличия необходимых компонентов
- Вывод инструкций по использованию Dashboard

## Опции конфигурации
- NAMESPACE: namespace где установлен Dashboard (по умолчанию: kubernetes-dashboard)
- SA_NAME: имя сервисного аккаунта (по умолчанию: admin-user)

## Примеры использования
1. Получение токена:
```bash
./dashboard-token.sh
```

2. Доступ к Dashboard:
- Запустите: kubectl proxy
- Откройте: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
- Используйте полученный токен для входа