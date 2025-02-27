# Use the official KIND node image as base
FROM kindest/node:v1.27.3

# Install NVIDIA dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Add NVIDIA container toolkit repository
RUN curl -s -L https://nvidia.github.io/nvidia-container-runtime/gpgkey | apt-key add - \
    && curl -s -L https://nvidia.github.io/nvidia-container-runtime/ubuntu20.04/nvidia-container-runtime.list > /etc/apt/sources.list.d/nvidia-container-runtime.list

# Install NVIDIA container runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    nvidia-container-runtime \
    && rm -rf /var/lib/apt/lists/*

# Configure containerd to use NVIDIA runtime
RUN mkdir -p /etc/containerd
COPY config.toml /etc/containerd/config.toml

# Configure systemd to work with cgroup v2
RUN mkdir -p /etc/systemd/system.conf.d/
COPY 10-cgroup-v2.conf /etc/systemd/system.conf.d/

# Set environment variables for NVIDIA
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Ensure systemd starts properly
RUN echo "DefaultTimeoutStartSec=5min" >> /etc/systemd/system.conf