#!/bin/bash

# Добавление меток для GPU на control-plane ноду
kubectl label node kind-control-plane nvidia.com/gpu=present --overwrite
kubectl label node kind-control-plane nvidia.com/cuda.capable=true --overwrite
kubectl label node kind-control-plane nvidia.com/cuda.runtime.major=12 --overwrite
kubectl label node kind-control-plane nvidia.com/cuda.runtime.minor=8 --overwrite
kubectl label node kind-control-plane nvidia.com/cuda.driver.major=550 --overwrite

# Добавление толераций
kubectl taint nodes kind-control-plane nvidia.com/gpu=present:NoSchedule --overwrite

# Проверка меток
echo "Проверка меток узла:"
kubectl get node kind-control-plane --show-labels

# Проверка толераций
echo "Проверка толераций узла:"
kubectl describe node kind-control-plane | grep Taints