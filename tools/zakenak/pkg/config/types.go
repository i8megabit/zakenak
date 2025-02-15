package config

// Config представляет основную конфигурацию проекта
type Config struct {
	Project     string         `yaml:"project"`
	Environment string         `yaml:"environment"`
	Registry    RegistryConfig `yaml:"registry,omitempty"`
	Deploy      DeployConfig   `yaml:"deploy"`
	Build       BuildConfig    `yaml:"build,omitempty"`
	Git         GitConfig      `yaml:"git,omitempty"`
}

// RegistryConfig содержит настройки container registry
type RegistryConfig struct {
	URL      string `yaml:"url"`
	Username string `yaml:"username,omitempty"`
	Password string `yaml:"password,omitempty"`
}

// DeployConfig содержит настройки развертывания
type DeployConfig struct {
	Namespace string   `yaml:"namespace"`
	Charts    []string `yaml:"charts"`
	Values    []string `yaml:"values,omitempty"`
}

// BuildConfig содержит настройки сборки
type BuildConfig struct {
	Context    string            `yaml:"context"`
	Dockerfile string            `yaml:"dockerfile"`
	Args       map[string]string `yaml:"args,omitempty"`
	GPU        GPUConfig         `yaml:"gpu,omitempty"`
}

// GitConfig содержит настройки Git
type GitConfig struct {
	Branch   string   `yaml:"branch"`
	Paths    []string `yaml:"paths"`
	Strategy string   `yaml:"strategy,omitempty"`
}

// GPUConfig содержит настройки NVIDIA GPU
type GPUConfig struct {
	Enabled  bool   `yaml:"enabled"`
	Runtime  string `yaml:"runtime,omitempty"`
	Memory   string `yaml:"memory,omitempty"`
	Devices  string `yaml:"devices,omitempty"`
}Docker Desktop - WSL distro te