package build

import (
	"testing"

	"github.com/i8megabit/zakenak/pkg/config"
)

func TestBuilderConfigure(t *testing.T) {
	cfg := &config.BuildConfig{}
	b := NewBuilder(cfg)
	if err := b.Configure(); err != nil {
		t.Fatalf("configure error: %v", err)
	}

	if cfg.Capabilities == nil || *cfg.Capabilities != "compute,utility" {
		t.Errorf("capabilities not set: %v", cfg.Capabilities)
	}
	if cfg.Requirements == nil || *cfg.Requirements != "cuda>=12.8" {
		t.Errorf("requirements not set: %v", cfg.Requirements)
	}
}
