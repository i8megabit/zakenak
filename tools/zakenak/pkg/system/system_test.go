package system

import "testing"

func TestGenerateKindConfig(t *testing.T) {
	info := &SystemInfo{
		OS:           "linux",
		Architecture: "amd64",
		CUDAVersion:  "12.8",
		WSLLibPath:   "/usr/lib/wsl/lib",
		CUDALibPath:  "/usr/local/cuda",
		HasNvidia:    true,
		PortMappings: []PortMapping{{Container: 80, Host: 80}},
	}

	cfg := info.GenerateKindConfig()

	if !contains(cfg, "/usr/local/cuda") || !contains(cfg, "nvidia.com/gpu=present") {
		t.Errorf("generated config missing expected values:\n%s", cfg)
	}
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || (len(s) > len(substr) && (stringIndex(s, substr) >= 0)))
}

func stringIndex(s, substr string) int {
	for i := 0; i+len(substr) <= len(s); i++ {
		if s[i:i+len(substr)] == substr {
			return i
		}
	}
	return -1
}
