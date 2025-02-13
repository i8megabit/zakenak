#!/bin/bash

# Создание директории manifests, если она не существует
mkdir -p ./tools/k8s-kind-setup/manifests

echo "Applying CoreDNS custom configuration..."
kubectl apply -f ./tools/k8s-kind-setup/manifests/coredns-custom-config.yaml

echo "Patching CoreDNS ConfigMap..."
kubectl apply -f ./tools/k8s-kind-setup/manifests/coredns-patch.yaml

echo "Restarting CoreDNS pods..."
kubectl rollout restart deployment coredns -n kube-system

echo "Waiting for CoreDNS to be ready..."
kubectl rollout status deployment coredns -n kube-system --timeout=60s

echo "Testing DNS resolution..."
echo "Testing webui.prod.local..."
kubectl run -i --rm --restart=Never busybox --image=busybox:1.28 -- nslookup webui.prod.local

echo "Testing ollama.prod.local..."
kubectl run -i --rm --restart=Never busybox --image=busybox:1.28 -- nslookup ollama.prod.local

echo "DNS setup completed!"