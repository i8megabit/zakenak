/*
 * Copyright (c) 2024 Mikhail Eberil
 * 
 * This file is part of Ƶakenak, a GitOps deployment tool.
 * 
 * Ƶakenak is free software: you can redistribute it and/or modify
 * it under the terms of the MIT License with Trademark Protection.
 * 
 * Ƶakenak is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * MIT License for more details.
 * 
 * The name "Ƶakenak" and associated branding are trademarks of @ӗberil
 * and may not be used without express written permission.
 */

package kind

import (
	"os"
	"path/filepath"
	"text/template"
)

// Config представляет конфигурацию Kind кластера
type Config struct {
	GPUEnabled bool
	ExtraMounts []Mount
}

// Mount представляет дополнительное монтирование
type Mount struct {
	HostPath      string
	ContainerPath string
}

// DefaultConfig возвращает конфигурацию по умолчанию
func DefaultConfig() *Config {
	return &Config{
		GPUEnabled: true,
		ExtraMounts: []Mount{
			{HostPath: "/usr/lib/wsl/lib", ContainerPath: "/usr/lib/wsl/lib"},
			{HostPath: "/usr/local/cuda-12.8", ContainerPath: "/usr/local/cuda-12.8"},
			{HostPath: "/usr/local/cuda", ContainerPath: "/usr/local/cuda"},
			{HostPath: "/usr/lib/wsl/lib/libcuda.so.1", ContainerPath: "/usr/lib/wsl/lib/libcuda.so.1"},
			{HostPath: "/usr/lib/wsl/lib/libnvidia-ml.so.1", ContainerPath: "/usr/lib/wsl/lib/libnvidia-ml.so.1"},
			{HostPath: "/dev/nvidia0", ContainerPath: "/dev/nvidia0"},
			{HostPath: "/dev/nvidiactl", ContainerPath: "/dev/nvidiactl"},
			{HostPath: "/dev/nvidia-uvm", ContainerPath: "/dev/nvidia-uvm"},
			{HostPath: "/dev/nvidia-uvm-tools", ContainerPath: "/dev/nvidia-uvm-tools"},
			{HostPath: "/dev/nvidia-modeset", ContainerPath: "/dev/nvidia-modeset"},
		},
	}
}

// GenerateConfig генерирует файл конфигурации Kind
func (c *Config) GenerateConfig(path string) error {
	tmpl := template.Must(template.New("kind-config").Parse(kindConfigTemplate))

	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()

	return tmpl.Execute(f, c)
}

const kindConfigTemplate = `kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true,nvidia.com/gpu=present"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  extraMounts:
  {{- range .ExtraMounts }}
  - hostPath: {{ .HostPath }}
    containerPath: {{ .ContainerPath }}
  {{- end }}
`