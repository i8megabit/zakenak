package config

import "fmt"

// GPUConfig содержит настройки для GPU
type GPUConfig struct {
	EnableGPU      bool   `yaml:"enableGPU"`      // Включить поддержку GPU
	NvidiaRuntime  string `yaml:"nvidiaRuntime"`  // Runtime для NVIDIA
	GPUCount       int    `yaml:"gpuCount"`       // Количество GPU
	MemoryLimit    string `yaml:"memoryLimit"`    // Лимит памяти
	ComputeMode    string `yaml:"computeMode"`    // Режим вычислений
}

// DefaultGPUConfig возвращает конфигурацию GPU по умолчанию
func DefaultGPUConfig() *GPUConfig {
	return &GPUConfig{
		EnableGPU:      true,
		NvidiaRuntime:  "nvidia",
		GPUCount:       1,
		MemoryLimit:    "8Gi",
		ComputeMode:    "default",
	}
}

// Validate проверяет корректность конфигурации GPU
func (g *GPUConfig) Validate() error {
	if g.EnableGPU {
		if g.GPUCount < 1 {
			return fmt.Errorf("количество GPU должно быть больше 0")
		}
		if g.NvidiaRuntime == "" {
			return fmt.Errorf("не указан NVIDIA runtime")
		}
	}
	return nil
}