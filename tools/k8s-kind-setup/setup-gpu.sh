#!/bin/bash

# Проверка наличия GPU
if nvidia-smi &> /dev/null; then
	echo "GPU обнаружен, настраиваем поддержку CUDA..."
	
	# Добавление меток для GPU на control-plane ноду
	kubectl label node kind-control-plane nvidia.com/gpu=present --overwrite
	
	# Добавление taint для GPU
	kubectl taint nodes kind-control-plane nvidia.com/gpu=present:NoSchedule --overwrite
	
	# Обновление значений для ollama
	helm upgrade ollama ./helm-charts/ollama \
		--namespace prod \
		--set deployment.useGPU=true \
		--reuse-values
	
	echo "GPU настройка завершена"
else
	echo "GPU не обнаружен, используем CPU режим"
	
	# Удаление меток GPU если они есть
	kubectl label node kind-control-plane nvidia.com/gpu- --overwrite
	kubectl taint nodes kind-control-plane nvidia.com/gpu- --overwrite
	
	# Обновление значений для ollama
	helm upgrade ollama ./helm-charts/ollama \
		--namespace prod \
		--set deployment.useGPU=false \
		--reuse-values
fi

