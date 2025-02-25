package cluster

import (
    "context"
    "fmt"
    "os/exec"
    "strings"
    "time"
)

// Manager manages Docker Desktop Kubernetes cluster
type Manager struct {
    name string
}

// NewManager creates a new cluster manager
func NewManager(name string) *Manager {
    return &Manager{
        name: name,
    }
}

// VerifyCluster checks if Docker Desktop Kubernetes is running
func (m *Manager) VerifyCluster(ctx context.Context) error {
    // Check if Docker Desktop is running
    cmd := exec.CommandContext(ctx, "docker", "info")
    if err := cmd.Run(); err != nil {
        return fmt.Errorf("Docker Desktop is not running: %w", err)
    }

    // Check if Kubernetes is enabled in Docker Desktop
    cmd = exec.CommandContext(ctx, "kubectl", "config", "current-context")
    output, err := cmd.Output()
    if err != nil {
        return fmt.Errorf("Kubernetes is not enabled in Docker Desktop: %w", err)
    }

    if !strings.Contains(string(output), "docker-desktop") {
        return fmt.Errorf("current context is not docker-desktop")
    }

    return nil
}

// WaitForCluster waits for the cluster to be ready
func (m *Manager) WaitForCluster(ctx context.Context) error {
    cmd := exec.CommandContext(ctx, "kubectl", "wait", "--for=condition=Ready", "nodes", "--all", "--timeout=300s")
    return cmd.Run()
}

// EnableKubernetes ensures Kubernetes is enabled in Docker Desktop
func (m *Manager) EnableKubernetes(ctx context.Context) error {
    // Check if Kubernetes is already enabled
    if err := m.VerifyCluster(ctx); err == nil {
        return nil
    }

    return fmt.Errorf("please enable Kubernetes in Docker Desktop settings and try again")
}