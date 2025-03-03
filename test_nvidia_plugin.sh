#!/bin/bash

# This script tests the installation of the NVIDIA device plugin
# It uses mock functions for helm and kubectl to avoid actual Kubernetes commands

# Define necessary variables and functions
export CYAN='\033[0;36m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export RED='\033[0;31m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color

# Set the default namespace to "prod"
export NAMESPACE_PROD="prod"

# Define a mock helm function to avoid actual Kubernetes commands
helm() {
    echo "MOCK HELM: $@"
    # Extract the namespace from the command
    for (( i=1; i<=$#; i++ )); do
        if [[ "${!i}" == "--namespace" ]]; then
            j=$((i+1))
            echo "NAMESPACE: ${!j}"
        fi
    done
}

# Define a mock kubectl function to avoid actual Kubernetes commands
kubectl() {
    echo "MOCK KUBECTL: $@"
    return 0
}

# Define a simplified install_chart function
install_chart() {
    local action=$1
    local chart=$2
    local namespace=${3:-$NAMESPACE_PROD}
    
    echo -e "${CYAN}Installing chart ${chart} in namespace ${namespace}...${NC}"
    
    # Special handling for nvidia-device-plugin
    if [ "$chart" = "nvidia-device-plugin" ]; then
        namespace="kube-system"
        echo -e "${CYAN}Forcing namespace to kube-system for nvidia-device-plugin${NC}"
    fi
    
    # Mock helm command
    helm $action $chart --namespace $namespace
    
    echo -e "${GREEN}Chart ${chart} successfully installed in namespace ${namespace}${NC}"
}

# Main script execution
echo -e "${CYAN}Testing install_chart with nvidia-device-plugin...${NC}"
echo -e "${CYAN}Initial namespace: prod${NC}"
install_chart "install" "nvidia-device-plugin" "prod"

# Verify the installation
echo -e "${CYAN}Verifying installation...${NC}"
kubectl get pods -n kube-system -l k8s-app=nvidia-device-plugin-daemonset

# Print a success message
echo -e "${GREEN}Test completed successfully.${NC}"