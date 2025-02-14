#!/bin/bash

echo "Настройка режима CPU с сохранением GPU конфигурации..."

# Обновление значений для ollama
helm upgrade ollama ./helm-charts/ollama \
	--namespace prod \
	--set deployment.useGPU=false \
	--reuse-values

echo "Конфигурация обновлена, под работает в режиме CPU с сохранёнными GPU переменными"



