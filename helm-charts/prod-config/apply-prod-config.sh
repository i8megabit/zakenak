#!/bin/bash

# Script to apply the production configuration for eberil.ru

# Check if certificate and key files are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <certificate-file> <key-file>"
    echo "Example: $0 /path/to/certificate.pem /path/to/private-key.pem"
    exit 1
fi

CERT_FILE=$1
KEY_FILE=$2

# Check if the files exist
if [ ! -f "$CERT_FILE" ]; then
    echo "Certificate file not found: $CERT_FILE"
    exit 1
fi

if [ ! -f "$KEY_FILE" ]; then
    echo "Key file not found: $KEY_FILE"
    exit 1
fi

# Create the TLS secret
echo "Creating TLS secret with the provided certificate and key..."
kubectl create secret tls eberil-ru-tls \
  --cert=$CERT_FILE \
  --key=$KEY_FILE \
  --namespace=prod \
  --dry-run=client -o yaml | kubectl apply -f -

# Apply the cert-manager configuration
echo "Applying cert-manager configuration..."
helm upgrade --install cert-manager jetstack/cert-manager \
  -f prod-config/cert-manager-values.yaml \
  --namespace prod

# Apply the ingress-nginx configuration
echo "Applying ingress-nginx configuration..."
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -f prod-config/ingress-nginx-values.yaml \
  --namespace prod

# Apply the kubernetes-dashboard configuration
echo "Applying kubernetes-dashboard configuration..."
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  -f prod-config/kubernetes-dashboard-values.yaml \
  --namespace prod

# Apply the open-webui configuration
echo "Applying open-webui configuration..."
helm upgrade --install open-webui ./open-webui \
  -f prod-config/open-webui-values.yaml \
  --namespace prod

# Apply the ingress configuration
echo "Applying ingress configuration..."
kubectl apply -f prod-config/ingress.yaml

# Verify the configuration
echo "Verifying the configuration..."
echo "Checking ingress resources:"
kubectl get ingress -n prod

echo "Checking TLS secret:"
kubectl get secret eberil-ru-tls -n prod

echo "Configuration applied successfully!"
echo ""
echo "You can now access the following endpoints:"
echo "- https://eberil.ru/dashboard - Kubernetes Dashboard"
echo "- https://eberil.ru/webui - Open WebUI"
echo "- https://dashboard.prod.local - Kubernetes Dashboard (internal)"
echo "- https://webui.prod.local - Open WebUI (internal)"
echo ""
echo "Make sure your DNS is properly configured to point eberil.ru to your ingress controller's IP address."