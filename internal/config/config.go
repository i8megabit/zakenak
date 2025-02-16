package config

// Config represents the application configuration
type Config struct {
	GPU GPUConfig
}

// GPUConfig represents GPU-specific configuration
type GPUConfig struct {
	Enabled bool
}

// Load loads the configuration from environment/files
func Load() (*Config, error) {
	return &Config{
		GPU: GPUConfig{
			Enabled: true,
		},
	}, nil
}