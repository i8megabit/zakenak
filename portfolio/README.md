# Mikhail Eberil - Technical Portfolio

## About Me

I am a seasoned DevOps Engineer and Cloud Infrastructure Architect with extensive experience in Kubernetes, containerization, CI/CD pipelines, and infrastructure automation. My expertise spans across cloud platforms, on-premises infrastructure, and hybrid environments, with a strong focus on high-availability systems and GPU-accelerated workloads.

## Skills Overview

- **Kubernetes Orchestration**: Advanced cluster management, GitOps workflows, custom operators
- **Cloud Infrastructure**: Multi-cloud deployments, IaC with Terraform, cloud-native architectures
- **DevOps Practices**: CI/CD pipelines, automation, monitoring, observability
- **Container Technologies**: Docker, Kubernetes, Helm, container security
- **AI/ML Infrastructure**: GPU-accelerated workloads, ML model serving, distributed training
- **Networking**: Advanced routing, service mesh, ingress controllers, network policies
- **Security**: RBAC, secret management, certificate management, network policies

## Featured Project: Zakenak

[Zakenak](https://github.com/i8megabit/zakenak) is a professional GitOps tool for efficient Kubernetes cluster orchestration with GPU support through Helm.

### Key Contributions

#### Kubernetes Architecture & Deployment

I designed and implemented a comprehensive Kubernetes deployment solution that includes:

- **Automated Cluster Setup**: Created scripts for automated deployment of Kind clusters with GPU support
- **Helm Chart Development**: Developed custom Helm charts for various components including:
  - Certificate management with cert-manager
  - Local CA for internal TLS
  - Kubernetes Dashboard for cluster monitoring
  - Ollama for AI model serving with GPU acceleration
  - Open WebUI for user-friendly AI interaction

#### GPU Integration in Kubernetes

Implemented advanced GPU support in Kubernetes:

- **NVIDIA Device Plugin**: Configured and optimized the NVIDIA device plugin for Kubernetes
- **GPU Resource Management**: Implemented resource quotas and limits for GPU resources
- **WSL2 GPU Passthrough**: Created detailed documentation and automation for GPU passthrough in WSL2

#### GitOps Workflow Implementation

Established a robust GitOps workflow:

- **State Management**: Developed a state management system for tracking cluster configuration
- **Automated Convergence**: Implemented automated convergence to ensure cluster state matches desired configuration
- **Version Control Integration**: Integrated with Git for configuration management and change tracking

#### AI Infrastructure Deployment

Built a complete AI infrastructure stack:

- **Model Serving**: Deployed Ollama for efficient AI model serving with GPU acceleration
- **User Interface**: Integrated Open WebUI for user-friendly interaction with AI models
- **Resource Optimization**: Implemented resource optimization strategies for efficient GPU utilization

## Technical Deep Dives

### [Kubernetes Dashboard Access](https://eberil.ru/dashboard)

The Kubernetes Dashboard provides a comprehensive UI for managing cluster resources. I've configured it with:

- Secure authentication using tokens
- RBAC for fine-grained access control
- Metrics integration for resource monitoring
- Custom resource visualization

### [Open WebUI for AI Interaction](https://eberil.ru/webui)

The Open WebUI provides a user-friendly interface for interacting with AI models. Key features include:

- Integration with Ollama for model serving
- Optimized for low-latency responses
- Support for various AI models
- Custom prompt templates

## Developed Tools and Scripts

### Kubernetes Management Tools

#### [deploy-all](../tools/k8s-kind-setup/deploy-all/src/deploy-all.sh)
A comprehensive deployment orchestration script that automates the entire process of setting up a Kubernetes cluster with all necessary components. Features include:
- Intelligent error detection and recovery
- Support for both GPU and CPU-only modes
- Automated installation of all required components
- Extensive validation and testing

#### [charts.sh](../tools/k8s-kind-setup/charts/src/charts.sh)
A powerful Helm charts management tool that simplifies the installation and configuration of Kubernetes components:
- Automated chart dependency resolution
- Support for custom values and configurations
- Intelligent ordering of chart installations
- Comprehensive error handling

#### [setup-dns](../tools/k8s-kind-setup/setup-dns/src/setup-dns.sh)
A specialized tool for configuring DNS in Kubernetes clusters:
- CoreDNS configuration for local domain resolution
- Integration with Windows hosts for local development
- Support for custom DNS configurations
- Automated validation of DNS setup

### GPU Integration Tools

#### [setup-wsl-gpu.sh](../tools/k8s-kind-setup/wsl/src/setup-wsl-gpu.sh)
A script for configuring GPU support in WSL2 environments:
- Automated NVIDIA driver configuration
- CUDA toolkit installation and setup
- Container runtime configuration for GPU support
- Comprehensive validation of GPU functionality

#### [check-cuda.sh](../tools/k8s-kind-setup/scripts/check-cuda.sh)
A validation script for ensuring proper CUDA configuration:
- Verification of NVIDIA driver installation
- CUDA toolkit validation
- Container runtime compatibility checks
- Tensor operations testing

### Utility Scripts

#### [dashboard-token.sh](../tools/k8s-kind-setup/dashboard-token/src/dashboard-token.sh)
A utility for generating and managing Kubernetes Dashboard access tokens:
- Secure token generation
- RBAC configuration
- Access control management
- Token rotation support

#### [connectivity-check](../tools/k8s-kind-setup/connectivity-check/src/check-services.sh)
A comprehensive connectivity validation tool:
- Service endpoint verification
- Network policy validation
- Ingress controller testing
- Cross-namespace communication checks

## Contact Information

- **GitHub**: [i8megabit](https://github.com/i8megabit)
- **Email**: i8megabit@gmail.com

[View My Resume](../resume/README.md)