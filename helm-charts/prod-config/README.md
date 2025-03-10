# Production Configuration for eberil.ru

This directory contains the production configuration for the ingress controller and cert-manager to use a purchased SSL certificate for the domain eberil.ru.

## Overview

The configuration in this directory allows for:

1. Routing traffic from eberil.ru/dashboard to the Kubernetes dashboard
2. Routing traffic from eberil.ru/webui to the Open WebUI
3. Maintaining access to the internal endpoints (dashboard.prod.local and webui.prod.local) in both production and test configurations
4. Using a purchased SSL certificate for all endpoints

## Files

- `cluster-issuer.yaml`: Configuration for the ClusterIssuer that will use the purchased certificate
- `tls-secret.yaml`: Template for the TLS secret that will hold the purchased certificate
- `ingress.yaml`: Ingress configuration for routing eberil.ru traffic
- `kubernetes-dashboard-values.yaml`: Updated values for the Kubernetes dashboard
- `open-webui-values.yaml`: Updated values for the Open WebUI
- `cert-manager-values.yaml`: Updated values for cert-manager
- `ingress-nginx-values.yaml`: Updated values for the ingress-nginx controller

## Usage

1. First, create the TLS secret with your purchased certificate:

   ```bash
   # Replace these with your actual certificate and key files
   CERT_FILE=/path/to/certificate.pem
   KEY_FILE=/path/to/private-key.pem
   
   # Create the secret
   kubectl create secret tls eberil-ru-tls \
     --cert=$CERT_FILE \
     --key=$KEY_FILE \
     --namespace=prod
   ```

2. Apply the updated configurations:

   ```bash
   # Apply the cert-manager configuration
   helm upgrade --install cert-manager jetstack/cert-manager \
     -f prod-config/cert-manager-values.yaml \
     --namespace prod

   # Apply the ingress-nginx configuration
   helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
     -f prod-config/ingress-nginx-values.yaml \
     --namespace prod

   # Apply the kubernetes-dashboard configuration
   helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
     -f prod-config/kubernetes-dashboard-values.yaml \
     --namespace prod

   # Apply the open-webui configuration
   helm upgrade --install open-webui ./open-webui \
     -f prod-config/open-webui-values.yaml \
     --namespace prod

   # Apply the ingress configuration
   kubectl apply -f prod-config/ingress.yaml
   ```

3. Verify that everything is working:

   ```bash
   # Check that the ingress is properly configured
   kubectl get ingress -n prod
   
   # Check that the TLS secret is properly configured
   kubectl get secret eberil-ru-tls -n prod
   ```

4. Test the endpoints:
   - https://eberil.ru/dashboard should lead to the Kubernetes dashboard
   - https://eberil.ru/webui should lead to the Open WebUI
   - https://dashboard.prod.local should still work
   - https://webui.prod.local should still work

## Notes

- The internal endpoints (dashboard.prod.local and webui.prod.local) will continue to work as before, but will now use the purchased certificate.
- The eberil.ru endpoints will route traffic to the appropriate services.
- Make sure your DNS is properly configured to point eberil.ru to your ingress controller's IP address.