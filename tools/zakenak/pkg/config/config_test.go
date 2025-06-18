package config

import (
	"os"
	"testing"
)

func TestLoadConfig(t *testing.T) {
	data := `
project: demo
registry:
  url: example.com
deploy:
  namespace: dev
build:
  context: .
  dockerfile: Dockerfile
  gpu:
    enabled: true
    memory: "8Gi"
git:
  branch: main
`
	tmp := t.TempDir()
	cfgPath := tmp + "/config.yaml"
	if err := os.WriteFile(cfgPath, []byte(data), 0644); err != nil {
		t.Fatalf("write config: %v", err)
	}

	cfg, err := LoadConfig(cfgPath)
	if err != nil {
		t.Fatalf("load config: %v", err)
	}

	if cfg.Project != "demo" {
		t.Errorf("unexpected project: %+v", cfg)
	}
	if cfg.Deploy.Namespace != "dev" {
		t.Errorf("deploy not parsed: %+v", cfg.Deploy)
	}
	if !cfg.Build.GPU.Enabled || cfg.Build.GPU.Memory != "8Gi" {
		t.Errorf("gpu not parsed: %+v", cfg.Build.GPU)
	}
}
