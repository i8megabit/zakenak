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
1.0.3

## Описание
Helm чарт для развертывания Open WebUI в Kubernetes кластере с поддержкой GPU через интеграцию с Ollama.

## Особенности
- Интеграция с централизованным управлением GPU
- Оптимизированная работа с Ollama через GPU
- Поддержка модели deepseek-r1:14b
- Эффективное управление GPU памятью
- Встроенная поддержка TLS
- Интеграция с Ingress-контроллером

## Требования
- Kubernetes 1.19+
- Helm 3.0+
- Ollama с GPU поддержкой
- NVIDIA GPU (RTX 4080 или выше)
- CUDA Toolkit 12.8+
- Ingress контроллер

## Использование
```bash
./tools/k8s-kind-setup/charts/src/charts.sh install open-webui -n prod
```

## Конфигурация
### Основные параметры
| Параметр | Описание | По умолчанию |
|----------|-----------|--------------|
| `deployment.replicas` | Количество реплик | `1` |
| `service.port` | Порт сервиса | `8080` |
| `service.targetPort` | Целевой порт | `8080` |
| `ingress.enabled` | Включение ingress | `true` |

### Переменные окружения
| Переменная | Описание | По умолчанию |
|------------|-----------|--------------|
| `OLLAMA_API_HOST` | Адрес Ollama API | `http://ollama:11434` |
| `GPU_MEMORY_UTILIZATION` | Использование GPU памяти | `0.9` |
| `MAX_PARALLEL_REQUESTS` | Макс. параллельных запросов | `5` |

## Устранение неполадок
### Проверка подключения к Ollama
```bash
kubectl exec -it -n prod $(kubectl get pods -n prod -l app=open-webui -o name) -- curl -f http://ollama:11434/api/version
```

### Мониторинг GPU использования
```bash
kubectl exec -it -n prod $(kubectl get pods -n prod -l app=ollama -o name) -- nvidia-smi
```

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