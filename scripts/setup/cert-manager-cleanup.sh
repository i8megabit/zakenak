#!/bin/bash

# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# Script for cleaning up cert-manager resources

set -e

echo "Cleaning up cert-manager resources..."

# Remove existing cert-manager installation if exists
helm uninstall cert-manager --namespace prod || true

# Delete the CRDs
kubectl delete crd certificaterequests.cert-manager.io --ignore-not-found=true
kubectl delete crd certificates.cert-manager.io --ignore-not-found=true
kubectl delete crd challenges.acme.cert-manager.io --ignore-not-found=true
kubectl delete crd clusterissuers.cert-manager.io --ignore-not-found=true
kubectl delete crd issuers.cert-manager.io --ignore-not-found=true
kubectl delete crd orders.acme.cert-manager.io --ignore-not-found=true

# Wait for CRDs to be fully removed
echo "Waiting for CRDs to be removed..."
sleep 5

echo "Cert-manager cleanup completed"