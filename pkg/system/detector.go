package system

import (
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"
)

// SystemDetector provides system information
type SystemDetector struct{}

// GetSystemInfo returns basic system information
func (d *SystemDetector) GetSystemInfo() (string, string) {
	return runtime.GOOS, runtime.GOARCH
}



// Platform определяет тип платформы
type Platform string

const (
	PlatformWSL    Platform = "wsl"
	PlatformUbuntu Platform = "ubuntu"
	PlatformOther  Platform = "other"
)

// KindVersion представляет версию Kind API
type KindVersion struct {
	API     string
	Runtime string
}

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
	Platform        Platform
	GPUAvailable    bool
	CUDAVersion     string
	WSLVersion      string
	DockerRuntime   string
	CUDAPath        string
	WSLLibPath      string
	RuntimePaths    []string
	PortMappings    []PortMapping
	KindVersion     KindVersion
}

// detectKindVersion определяет версию Kind API
func detectKindVersion() KindVersion {
	version := KindVersion{
		API:     "v1alpha4", // значение по умолчанию
		Runtime: "docker",
	}

	// Проверка версии kind
	if out, err := exec.Command("kind", "version").Output(); err == nil {
		versionStr := strings.TrimSpace(string(out))
		// Если версия >= 0.20.0, используем более новую версию API
		if strings.Contains(versionStr, "v0.20") || strings.Contains(versionStr, "v0.21") {
			version.API = "v1beta1"
		}
	}

	// Проверка container runtime
	if out, err := exec.Command("docker", "info", "--format", "{{.DefaultRuntime}}").Output(); err == nil {
		version.Runtime = strings.TrimSpace(string(out))
	}

	return version
}

// detectPlatform определяет текущую платформу
func detectPlatform() Platform {
	// Проверка WSL
	if out, err := exec.Command("uname", "-r").Output(); err == nil {
		if strings.Contains(strings.ToLower(string(out)), "microsoft") {
			return PlatformWSL
		}
	}

	// Проверка Ubuntu
	if _, err := os.ReadFile("/etc/lsb-release"); err == nil {
		return PlatformUbuntu
	}

	return PlatformOther
}

// Detect определяет системную информацию
func Detect() (*SystemInfo, error) {
	info := &SystemInfo{
		OS:           runtime.GOOS,
		Architecture: runtime.GOARCH,
		Platform:     detectPlatform(),
		KindVersion:  detectKindVersion(),
		PortMappings: []PortMapping{
			{ContainerPort: 80, HostPort: 80, Protocol: "TCP"},
			{ContainerPort: 443, HostPort: 443, Protocol: "TCP"},
			{ContainerPort: 6443, HostPort: 6443, Protocol: "TCP"},
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
	config := fmt.Sprintf(`kind: Cluster
apiVersion: %s
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"`, si.KindVersion.API)

	// Добавляем специфичные для платформы настройки
	switch si.Platform {
	case PlatformWSL:
		config += `
  extraMounts:
  - hostPath: /usr/lib/wsl
    containerPath: /usr/lib/wsl
  - hostPath: /tmp
    containerPath: /tmp`
	case PlatformUbuntu:
		config += `
  extraMounts:
  - hostPath: /var/run/docker.sock
    containerPath: /var/run/docker.sock`
	}

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

	// Добавляем порты
	if len(si.PortMappings) > 0 {
		config += "\n  extraPortMappings:"
		for _, port := range si.PortMappings {
			config += fmt.Sprintf(`
  - containerPort: %d
    hostPort: %d
    protocol: %s`, port.ContainerPort, port.HostPort, port.Protocol)
		}
	}

	return config
}