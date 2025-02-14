#!/bin/bash

# Добавление меток для GPU на control-plane ноду
kubectl label node kind-control-plane nvidia.com/gpu=present --overwrite

# Добавление taint для GPU
kubectl taint nodes kind-control-plane nvidia.com/gpu=present:NoSchedule --overwrite

# Проверка настроек
echo "Проверка меток и taint узла:"
kubectl get node kind-control-plane --show-labels
kubectl describe node kind-control-plane | grep Taints

