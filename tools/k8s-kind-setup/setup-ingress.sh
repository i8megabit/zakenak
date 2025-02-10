#!/bin/bash

echo "Installing Nginx Ingress Controller..."

# Добавление репозитория ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Создание Certificate ресурсов
echo "Creating Certificate resources..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
	name: ollama-tls
	namespace: prod
spec:
	secretName: ollama-tls
	issuerRef:
		name: letsencrypt-prod
		kind: ClusterIssuer
	dnsNames:
		- "ollama.local.dev"
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
	name: open-webui-tls
	namespace: prod
spec:
	secretName: open-webui-tls
	issuerRef:
		name: letsencrypt-prod
		kind: ClusterIssuer
	dnsNames:
		- "webui.local.dev"
EOF

# Установка ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
		--namespace ingress-nginx \
		--create-namespace \
		--set controller.service.type=NodePort \
		--set controller.hostPort.enabled=true \
		--set controller.service.ports.http=80 \
		--set controller.service.ports.https=443 \
		--wait

# Проверка установки
echo "Checking ingress-nginx installation..."
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
echo "Checking Certificate resources..."
kubectl get certificates -n prod
kubectl get secrets -n prod
