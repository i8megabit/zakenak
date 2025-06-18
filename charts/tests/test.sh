#!/usr/bin/env bash
set -euo pipefail

# Create cluster using kind
kind create cluster

# Install cert-manager and wait for webhook
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set installCRDs=true --wait

# Install local-ca chart which depends on cert-manager
helm install test ../helm-charts/local-ca --namespace test --create-namespace --wait

kubectl get pods -n test
