# Ollama Helm Chart

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