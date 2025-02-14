#!/bin/bash

# Добавление меток для GPU на control-plane ноду
kubectl label node kind-control-plane nvidia.com/gpu=present --overwrite

# Добавление taint для GPU
kubectl taint nodes kind-control-plane nvidia.com/gpu=present:NoSchedule --overwrite

# Проверка драйверов NVIDIA
if ! command -v nvidia-smi &> /dev/null; then
	echo "NVIDIA drivers not found. Installing..."
	sudo apt-get update
	sudo apt-get install -y nvidia-driver-550-server
fi

# Проверка CUDA
if ! command -v nvcc &> /dev/null; then
	echo "CUDA not found. Installing CUDA 12.8..."
	wget https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda_12.8.0_545.23.06_linux.run
	sudo sh cuda_12.8.0_545.23.06_linux.run --silent --toolkit
fi

# Проверка настроек
echo "Проверка меток и taint узла:"
kubectl get node kind-control-plane --show-labels
kubectl describe node kind-control-plane | grep Taints

echo "Проверка статуса NVIDIA:"
nvidia-smi

