#!/bin/bash

# Добавление меток для GPU на control-plane ноду
kubectl label node kind-control-plane nvidia.com/gpu=present --overwrite
kubectl label node kind-control-plane nvidia.com/cuda.capable=true --overwrite

# Проверка меток
echo "Проверка меток узла:"
kubectl get node kind-control-plane --show-labels

# Создание RuntimeClass для nvidia
cat <<EOF | kubectl apply -f -
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
	name: nvidia
handler: nvidia
scheduling:
	nodeSelector:
		nvidia.com/gpu: "present"
	tolerations:
	- key: nvidia.com/gpu
		operator: Exists
		effect: NoSchedule
EOF