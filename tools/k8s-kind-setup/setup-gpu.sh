#!/bin/bash

# Добавление taint на ноду
kubectl taint nodes kind-control-plane nvidia.com/gpu=present:NoSchedule --overwrite

# Добавление меток для GPU на control-plane ноду
kubectl label node kind-control-plane nvidia.com/gpu=present --overwrite
kubectl label node kind-control-plane kubernetes.io/os=linux --overwrite

# Проверка настроек
echo "Проверка меток и taint узла:"
kubectl get node kind-control-plane --show-labels
kubectl describe node kind-control-plane | grep Taints
