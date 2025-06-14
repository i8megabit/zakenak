/*
 * (c) 2023-2025 Mikhail Eberil (@eberil)
 *
 * Этот файл — часть проекта Ƶakenak.
 * Распространяется по лицензии MIT.
 * Подробности см. в LICENSE.md в корне репозитория.
 *
 * ПО поставляется «как есть», без каких-либо гарантий,
 * включая подразумеваемые гарантии пригодности
 * или соответствия конкретным целям.
 * Использование имени «Ƶakenak» без разрешения запрещено.
 */

package kind

import (
	"os"
	"text/template"
)

// Config представляет конфигурацию Kind кластера
type Config struct {
	GPUEnabled  bool
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
