# Ollama Helm Chart
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
0.1.0

## Описание
Helm чарт для развертывания Ollama - сервера LLM моделей с поддержкой GPU в Kubernetes.

## Особенности
- Полная поддержка NVIDIA GPU в WSL2
- Оптимизированная конфигурация для модели deepseek-r1:14b
- Встроенная поддержка TLS через cert-manager
- Настраиваемые сетевые политики
- Персистентное хранилище для моделей

## Требования
- Kubernetes 1.19+
- Helm 3.0+
- NVIDIA GPU с поддержкой CUDA
- cert-manager для TLS
- Ingress контроллер

## Установка
```bash
helm install ollama ./helm-charts/ollama \
    --namespace prod \
    --create-namespace \
    --values values.yaml
```

## Конфигурация
### Основные параметры
| Параметр | Описание | По умолчанию |
|----------|-----------|--------------|
| `deployment.replicas` | Количество реплик | `1` |
| `deployment.useGPU` | Использование GPU | `true` |
| `deployment.resources.limits.nvidia.com/gpu` | Количество GPU | `1` |

### Переменные окружения
| Переменная | Описание | По умолчанию |
|------------|-----------|--------------|
| `OLLAMA_MODELS` | Модель для загрузки | `deepseek-r1:14b` |
| `OLLAMA_GPU_LAYERS` | Количество слоев на GPU | `43` |

## Мониторинг
Чарт включает базовые метрики Prometheus и может быть интегрирован с существующим стеком мониторинга.

## Безопасность
- Поддержка TLS через cert-manager
- Настраиваемые сетевые политики
- RBAC для доступа к ресурсам

## Устранение неполадок
### Проверка статуса пода
```bash
kubectl get pods -n prod -l app=ollama
kubectl logs -n prod -l app=ollama
```

### Проверка GPU
```bash
kubectl exec -it -n prod $(kubectl get pods -n prod -l app=ollama -o name) -- nvidia-smi
```

```plain text
Copyright (c)  2025 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

The name "Zakenak" and associated branding are trademarks of @eberil and may not be used without express written permission.
```