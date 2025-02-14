#!/bin/bash

echo "Настройка GPU для Ollama..."

# Получаем список узлов, где запущены поды Ollama
OLLAMA_NODES=$(kubectl get pods -n prod -l app=ollama -o jsonpath='{.items[*].spec.nodeName}')

if [ -z "$OLLAMA_NODES" ]; then
    echo "Не найдены поды Ollama в namespace prod"
    exit 1
fi

# Добавление меток GPU только на узлы с Ollama
for node in $OLLAMA_NODES; do
    echo "Добавление метки GPU на узел $node..."
    kubectl label node $node nvidia.com/gpu=present --overwrite
done

# Применение NVIDIA device plugin
echo "Применение NVIDIA device plugin..."
kubectl apply -f ../helm-charts/ollama/templates/nvidia-device-plugin.yaml

# Проверка статуса DaemonSet
echo "Ожидание запуска NVIDIA device plugin..."
kubectl rollout status daemonset/nvidia-device-plugin-daemonset -n prod

# Обновление значений для ollama с поддержкой GPU
echo "Обновление конфигурации Ollama..."
helm upgrade ollama ./helm-charts/ollama \
    --namespace prod \
    --set deployment.useGPU=true \
    --reuse-values

echo "Проверка статуса подов Ollama..."
kubectl get pods -n prod -l app=ollama

echo "Конфигурация GPU завершена"