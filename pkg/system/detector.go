package system

import (
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"
)

// PortMapping определяет маппинг портов для Kind
type PortMapping struct {
	ContainerPort int
	HostPort      int
	Protocol      string
}

// SystemInfo содержит информацию о системе
type SystemInfo struct {
	OS              string
	Architecture    string
	GPUAvailable    bool
	CUDAVersion     string
	WSLVersion      string
	DockerRuntime   string
	CUDAPath        string
	WSLLibPath      string
	RuntimePaths    []string
	PortMappings    []PortMapping
}

// Detect определяет системную информацию
func Detect() (*SystemInfo, error) {
	info := &SystemInfo{
		OS:           runtime.GOOS,
		Architecture: runtime.GOARCH,
		PortMappings: []PortMapping{
			{ContainerPort: 80, HostPort: 80, Protocol: "TCP"},
			{ContainerPort: 443, HostPort: 443, Protocol: "TCP"},
			{ContainerPort: 6443, HostPort: 6443, Protocol: "TCP"}, // Kubernetes API
		},
	}

	// Проверка GPU
	if _, err := exec.LookPath("nvidia-smi"); err == nil {
		info.GPUAvailable = true
		// Получение версии CUDA
		if out, err := exec.Command("nvidia-smi", "--query-gpu=driver_version", "--format=csv,noheader").Output(); err == nil {
			info.CUDAVersion = strings.TrimSpace(string(out))
		}
		
		// Определение путей CUDA
		cudaPaths := []string{
			"/usr/local/cuda",
			"/usr/local/cuda-12.8",
			"/usr/lib/cuda",
		}
		for _, path := range cudaPaths {
			if _, err := os.Stat(path); err == nil {
				info.CUDAPath = path
				break
			}
		}
		
		// Определение путей WSL
		wslPaths := []string{
			"/usr/lib/wsl/lib",
			"/usr/lib/wsl",
			"/usr/lib/nvidia-container-toolkit",
		}
		for _, path := range wslPaths {
			if _, err := os.Stat(path); err == nil {
				info.WSLLibPath = path
				break
			}
		}
		
		// Определение дополнительных путей runtime
		runtimePaths := []string{
			"/usr/bin/nvidia-container-runtime",
			"/usr/local/nvidia/toolkit",
		}
		for _, path := range runtimePaths {
			if _, err := os.Stat(path); err == nil {
				info.RuntimePaths = append(info.RuntimePaths, path)
			}
		}
	}

	// Проверка WSL
	if out, err := exec.Command("uname", "-r").Output(); err == nil {
		if strings.Contains(strings.ToLower(string(out)), "microsoft") {
			if out, err := exec.Command("wslpath", "--version").Output(); err == nil {
				info.WSLVersion = strings.TrimSpace(string(out))
			}
		}
	}

	// Проверка Docker runtime
	if out, err := exec.Command("docker", "info", "--format", "{{.DefaultRuntime}}").Output(); err == nil {
		info.DockerRuntime = strings.TrimSpace(string(out))
	}

	return info, nil
}

// GenerateKindConfig генерирует конфигурацию для Kind кластера
func (si *SystemInfo) GenerateKindConfig() string {
	config := `kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
	kind: InitConfiguration
	nodeRegistration:
	  kubeletExtraArgs:
		node-labels: "ingress-ready=true"`

	if si.GPUAvailable {
		config += `,nvidia.com/gpu=present`
		
		// Добавляем обнаруженные пути монтирования
		config += "\n  extraMounts:"
		
		// WSL библиотеки
		if si.WSLLibPath != "" {
			config += fmt.Sprintf(`
  - hostPath: %s
	containerPath: %s`, si.WSLLibPath, si.WSLLibPath)
		}
		
		// CUDA пути
		if si.CUDAPath != "" {
			config += fmt.Sprintf(`
  - hostPath: %s
	containerPath: %s`, si.CUDAPath, si.CUDAPath)
		}
		
		// Дополнительные пути runtime
		for _, path := range si.RuntimePaths {
			config += fmt.Sprintf(`
  - hostPath: %s
	containerPath: %s`, path, path)
		}
	}

	// Стандартные порты
	config += `
  extraPortMappings:
  - containerPort: 80
	hostPort: 80
  - containerPort: 443
	hostPort: 443`

	return config
}