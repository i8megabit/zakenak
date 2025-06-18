package state

import (
	"os"
	"testing"
)

func TestFileStateManager(t *testing.T) {
	dir := t.TempDir()
	path := dir + "/state.json"
	m := NewFileStateManager(path)

	// Load when file does not exist
	s, err := m.Load()
	if err != nil {
		t.Fatalf("initial load: %v", err)
	}
	if s.Status.Phase != PhaseInitializing || !s.GPU.Enabled {
		t.Errorf("unexpected default state: %+v", s)
	}

	// Update state
	if err := m.Update(func(st *State) error {
		st.Status.Phase = PhaseRunning
		st.Components["app"] = Component{Name: "app", Version: "1"}
		return nil
	}); err != nil {
		t.Fatalf("update: %v", err)
	}

	// Load again and verify
	s2, err := m.Load()
	if err != nil {
		t.Fatalf("second load: %v", err)
	}
	if s2.Status.Phase != PhaseRunning {
		t.Errorf("phase not updated: %v", s2.Status.Phase)
	}
	if _, ok := s2.Components["app"]; !ok {
		t.Errorf("component not saved")
	}

	// Check file exists
	if _, err := os.Stat(path); err != nil {
		t.Errorf("state file missing: %v", err)
	}
}
