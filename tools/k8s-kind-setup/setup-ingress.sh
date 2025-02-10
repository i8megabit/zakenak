#!/bin/bash

echo "Installing Nginx Ingress Controller..."

# Добавление репозитория ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Создание namespace prod если он не существует
echo "Creating prod namespace..."
kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -

# Проверка готовности cert-manager
echo "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=Available deployment --timeout=120s -n prod cert-manager
kubectl wait --for=condition=Available deployment --timeout=120s -n prod cert-manager-webhook

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

# Ожидание готовности первого ClusterIssuer
echo "Waiting for selfsigned-issuer to be ready..."
kubectl wait --for=condition=Ready clusterissuer selfsigned-issuer --timeout=60s

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

# Ожидание создания CA сертификата
echo "Waiting for CA certificate to be ready..."
kubectl wait --for=condition=Ready certificate -n prod local-ca --timeout=60s

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

# Ожидание готовности второго ClusterIssuer
echo "Waiting for local-ca-issuer to be ready..."
kubectl wait --for=condition=Ready clusterissuer local-ca-issuer --timeout=60s

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
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
	name: sidecar-injector-tls
	namespace: prod
spec:
	secretName: sidecar-injector-tls
	duration: 2160h
	renewBefore: 360h
	commonName: sidecar-injector.prod.svc
	dnsNames:
		- "sidecar-injector.prod.svc"
		- "sidecar-injector.prod.svc.cluster.local"
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
kubectl wait --for=condition=Ready certificate -n prod sidecar-injector-tls --timeout=120s

echo "Checking Certificate and Secret resources..."
kubectl get certificates -n prod
kubectl get secrets -n prod
