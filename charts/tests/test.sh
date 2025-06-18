#!/usr/bin/env bash
set -euo pipefail
kind create cluster
helm install test ../helm-charts/local-ca --namespace test --create-namespace
kubectl get all -n test
