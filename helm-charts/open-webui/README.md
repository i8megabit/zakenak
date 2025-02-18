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
Copyright (c) 2023-2025 Mikhail Eberil (@eberil)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```