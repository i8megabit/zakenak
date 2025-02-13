#!/bin/bash

echo "Applying CoreDNS custom configuration..."
kubectl apply -f ./manifests/coredns-custom-config.yaml

echo "Patching CoreDNS ConfigMap..."
kubectl apply -f ./manifests/coredns-patch.yaml

echo "Restarting CoreDNS pods..."
kubectl rollout restart deployment coredns -n kube-system

echo "Waiting for CoreDNS to be ready..."
kubectl rollout status deployment coredns -n kube-system --timeout=60s

echo "Testing DNS resolution..."
kubectl run -i --rm --restart=Never busybox --image=busybox:1.28 -- nslookup webui.prod.local
kubectl run -i --rm --restart=Never busybox --image=busybox:1.28 -- nslookup ollama.prod.local