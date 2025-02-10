#!/bin/bash

echo "Installing Nginx Ingress Controller..."

# Добавление репозитория ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Создание namespace prod если он не существует
kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -

# Создание ClusterIssuer для локальной среды
echo "Creating ClusterIssuer for local environment..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
	name: selfsigned-issuer
spec:
	selfSigned: {}
EOF

# Создание корневого CA сертификата
echo "Creating root CA certificate..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
	name: local-ca
	namespace: prod
spec:
	isCA: true
	commonName: local-ca
	secretName: local-ca-key-pair
	privateKey:
		algorithm: ECDSA
		size: 256
	issuerRef:
		name: selfsigned-issuer
		kind: ClusterIssuer
		group: cert-manager.io
EOF

# Создание ClusterIssuer использующего CA сертификат
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
	name: local-ca-issuer
spec:
	ca:
		secretName: local-ca-key-pair
EOF

# Ожидание создания секрета CA
echo "Waiting for CA secret to be created..."
kubectl wait --for=condition=Ready certificate -n prod local-ca --timeout=60s

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
	duration: 2160h
	renewBefore: 360h
	commonName: ollama.prod.local
	dnsNames:
		- "ollama.prod.local"
	issuerRef:
		name: local-ca-issuer
		kind: ClusterIssuer
		group: cert-manager.io
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
	name: open-webui-tls
	namespace: prod
spec:
	secretName: open-webui-tls
	duration: 2160h
	renewBefore: 360h
	commonName: webui.prod.local
	dnsNames:
		- "webui.prod.local"
	issuerRef:
		name: local-ca-issuer
		kind: ClusterIssuer
		group: cert-manager.io
EOF

# Установка ingress-nginx с поддержкой TLS
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
		--namespace ingress-nginx \
		--create-namespace \
		--set controller.service.type=NodePort \
		--set controller.hostPort.enabled=true \
		--set controller.service.ports.http=80 \
		--set controller.service.ports.https=443 \
		--set controller.extraArgs.default-ssl-certificate=prod/ollama-tls \
		--wait

# Проверка установки и ожидание создания секретов
echo "Checking ingress-nginx installation..."
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

echo "Waiting for Certificate resources to be ready..."
kubectl wait --for=condition=Ready certificate -n prod ollama-tls --timeout=120s
kubectl wait --for=condition=Ready certificate -n prod open-webui-tls --timeout=120s

echo "Checking Certificate and Secret resources..."
kubectl get certificates -n prod
kubectl get secrets -n prod
