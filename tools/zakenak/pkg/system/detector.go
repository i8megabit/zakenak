package system

import (
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"
)

// SystemInfo содержит информацию о системе
type SystemInfo struct {
	OS            string
	Architecture  string
	CUDAVersion   string
	WSLLibPath    string
	CUDALibPath   string
	HasNvidia     bool
	PortMappings  []PortMapping
}

// PortMapping описывает проброс портов
type PortMapping struct {
	Container int
	Host     int
}

// DefaultPorts возвращает стандартные порты для проброса
func DefaultPorts() []PortMapping {
	return []PortMapping{
		{Container: 80, Host: 80},
		{Container: 443, Host: 443},
	}
}

// Detect обнаруживает системные параметры
func Detect() (*SystemInfo, error) {
	info := &SystemInfo{
		OS:           runtime.GOOS,
		Architecture: runtime.GOARCH,
		PortMappings: DefaultPorts(),
	}

	// Проверка NVIDIA
	if _, err := exec.LookPath("nvidia-smi"); err == nil {
		info.HasNvidia = true
		
		// Определение версии CUDA
		out, err := exec.Command("nvidia-smi", "--query-gpu=driver_version", "--format=csv,noheader").Output()
		if err == nil {
			version := strings.TrimSpace(string(out))
			info.CUDAVersion = version
		}
	}

	// Определение путей библиотек
	wslLib := "/usr/lib/wsl/lib"
	if _, err := os.Stat(wslLib); err == nil {
		info.WSLLibPath = wslLib
	}

	// Поиск CUDA библиотек
	cudaPaths := []string{
		"/usr/local/cuda",
		"/usr/local/cuda-12.8",
	}
	for _, path := range cudaPaths {
		if _, err := os.Stat(path); err == nil {
			info.CUDALibPath = path
			break
		}
	}

	return info, nil
}

// GenerateKindConfig генерирует конфигурацию для Kind
func (s *SystemInfo) GenerateKindConfig() string {
	var mounts []string
	
	// Добавление WSL библиотек если они есть
	if s.WSLLibPath != "" {
		mounts = append(mounts, fmt.Sprintf(`  - hostPath: %s
	containerPath: %s`, s.WSLLibPath, s.WSLLibPath))
	}

	// Добавление CUDA библиотек если они есть
	if s.CUDALibPath != "" {
		mounts = append(mounts, fmt.Sprintf(`  - hostPath: %s
	containerPath: %s`, s.CUDALibPath, s.CUDALibPath))
	}

	// Формирование списка пробрасываемых портов
	var ports []string
	for _, p := range s.PortMappings {
		ports = append(ports, fmt.Sprintf(`  - containerPort: %d
	hostPort: %d`, p.Container, p.Host))
	}

	// Генерация полной конфигурации
	config := fmt.Sprintf(`kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
	kind: InitConfiguration
	nodeRegistration:
	  kubeletExtraArgs:
		node-labels: "ingress-ready=true%s"
  extraMounts:
%s
  extraPortMappings:
%s`,
		s.gpuLabels(),
		strings.Join(mounts, "\n"),
		strings.Join(ports, "\n"))

	return config
}

// gpuLabels возвращает метки для GPU если они доступны
func (s *SystemInfo) gpuLabels() string {
	if s.HasNvidia {
		return ",nvidia.com/gpu=present"
	}
	return ""
}