# Connectivity Check Tool
```ascii
     ______     _                      _    
    |___  /    | |                    | |   
       / / __ _| |  _ _   ___     ___ | |  _
      / / / _` | |/ / _`||  _ \ / _` || |/ /
     / /_| (_| |  < by_Eberil| | (_| ||   < 
    /_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\
  
    Should Harbour?	No.

## Версия
1.0.0

## Описание
Инструмент для комплексной проверки связности и работоспособности компонентов Kubernetes инфраструктуры. Позволяет быстро диагностировать проблемы с DNS, сетевой доступностью, сертификатами и состоянием подов.

## Особенности
- Проверка DNS резолвинга для сервисов
- Тестирование доступности портов
- Проверка HTTPS endpoints
- Мониторинг состояния подов
- Валидация сертификатов
- Диагностика Ingress конфигурации

## Требования
- Kubernetes кластер
- kubectl
- netcat (nc)
- curl
- bash 4.0+

## Быстрый старт
```bash
# Сделать скрипт исполняемым
chmod +x check-services.sh

# Запустить проверку
./check-services.sh
```

## Компоненты проверки

### 1. DNS резолвинг
Проверяет корректность разрешения доменных имен:
```bash
# Пример вывода
ollama.prod.local resolves to: 10.96.130.21
webui.prod.local resolves to: 10.96.130.21
```

### 2. Проверка портов
Тестирует доступность ключевых портов:
- 80 (HTTP)
- 443 (HTTPS)
- Специфичные порты сервисов

### 3. HTTPS доступность
Проверяет доступность HTTPS endpoints:
```bash
# Пример успешного ответа
HTTP/2 200 
date: Thu, 15 Feb 2024 10:00:00 GMT
content-type: text/html
server: nginx/1.25.3
```

### 4. Статус подов
Мониторинг состояния критических подов:
- ollama
- open-webui
- cert-manager
- ingress-controller

### 5. Сертификаты
Проверка состояния TLS сертификатов:
- Валидность
- Срок действия
- Корректность цепочки

## Устранение неполадок

### Проблемы с DNS
1. Проверьте конфигурацию CoreDNS:
```bash
kubectl get configmap -n kube-system coredns -o yaml
```

2. Проверьте логи CoreDNS:
```bash
kubectl logs -n kube-system -l k8s-app=kube-dns
```

### Недоступность HTTPS
1. Проверьте сертификаты:
```bash
kubectl get certificates -n prod
kubectl get secrets -n prod | grep tls
```

2. Проверьте Ingress:
```bash
kubectl describe ingress -n prod
```

### Проблемы с подами
1. Проверьте события:
```bash
kubectl get events -n prod --sort-by='.lastTimestamp'
```

2. Проверьте логи:
```bash
kubectl logs -n prod <pod-name>
```

## Примеры использования

### Базовая проверка
```bash
./check-services.sh
```

### Проверка с выводом в файл
```bash
./check-services.sh > connectivity-report.txt 2>&1
```

### Периодическая проверка
```bash
watch -n 60 ./check-services.sh
```

## Интерпретация результатов

### Успешная проверка
- DNS резолвинг работает корректно
- Все порты доступны
- HTTPS endpoints отвечают с кодом 200
- Поды в состоянии Running
- Сертификаты валидны

### Признаки проблем
- Ошибки DNS резолвинга
- Недоступные порты
- Ошибки HTTPS (4xx, 5xx)
- Поды в состоянии CrashLoopBackOff или Error
- Проблемы с сертификатами

## Поддержка
При возникновении проблем:
1. Проверьте последние изменения в инфраструктуре
2. Изучите логи компонентов
3. Создайте issue с полным отчетом проверки

```plain text
Copyright (c) 2024 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

The name "Zakenak" and associated branding are trademarks of @eberil and may not be used without express written permission.
```