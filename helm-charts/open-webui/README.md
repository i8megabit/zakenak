# Open WebUI Helm Chart
```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

Should Harbour?	No.
```
## Версия
1.0.2

## Описание
Helm чарт для развертывания Open WebUI в Kubernetes кластере.

## Последние изменения
- Добавлен Service для маршрутизации трафика
- Настроена интеграция с Ingress-контроллером
- Исправлена проблема с endpoints

## Использование
```bash
./tools/helm-deployer/deploy-chart.sh -e prod -c ./helm-charts/open-webui/
```

## Конфигурация
Для настройки используйте values.yaml файл в корне чарта.

### Важные параметры
- service.port: Порт сервиса
- service.targetPort: Целевой порт контейнера
- release.namespace: Namespace для развертывания

```plain text
Copyright (c) 2024 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

The name "Zakenak" and associated branding are trademarks of @eberil and may not be used without express written permission.
```