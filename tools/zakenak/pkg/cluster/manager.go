package cluster

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"github.com/i8megabit/zakenak/pkg/system"
)

// Manager предоставляет функционал для управления кластером
type Manager struct {
	workDir     string
	clusterName string
	noRemove    bool
	noGenerate  bool
	noRecreate  bool
}

// NewManager создает новый экземпляр Manager
func NewManager(workDir string, opts ...Option) *Manager {
	m := &Manager{
		workDir:     workDir,
		clusterName: "zakenak-cluster",
	}
	for _, opt := range opts {
		opt(m)
	}
	return m
}

// Option определяет опцию конфигурации Manager
type Option func(*Manager)

// WithNoRemove устанавливает флаг noRemove
func WithNoRemove(noRemove bool) Option {
	return func(m *Manager) {
		m.noRemove = noRemove
	}
}

// WithNoGenerate устанавливает флаг noGenerate
func WithNoGenerate(noGenerate bool) Option {
	return func(m *Manager) {
		m.noGenerate = noGenerate
	}
}

// WithNoRecreate устанавливает флаг noRecreate
func WithNoRecreate(noRecreate bool) Option {
	return func(m *Manager) {
		m.noRecreate = noRecreate
	}
}

// Setup выполняет полную настройку кластера
func (m *Manager) Setup(ctx context.Context) error {
	if err := m.checkDependencies(); err != nil {
		return fmt.Errorf("dependency check failed: %w", err)
	}

	if err := m.setupDockerNvidia(); err != nil {
		return fmt.Errorf("docker/nvidia setup failed: %w", err)
	}

	if err := m.setupCluster(ctx); err != nil {
		return fmt.Errorf("cluster setup failed: %w", err)
	}

	if !m.noGenerate {
		if err := m.generateConfig(); err != nil {
			return fmt.Errorf("config generation failed: %w", err)
		}
	}

	return nil
}

// checkDependencies проверяет наличие необходимых зависимостей
func (m *Manager) checkDependencies() error {
	deps := []string{"docker", "nvidia-smi", "kind"}
	for _, dep := range deps {
		if _, err := exec.LookPath(dep); err != nil {
			return fmt.Errorf("%s not found: %w", dep, err)
		}
	}
	return nil
}

// setupDockerNvidia настраивает Docker и NVIDIA
func (m *Manager) setupDockerNvidia() error {
	cmd := exec.Command("nvidia-ctk", "runtime", "configure", "--runtime=docker")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to configure nvidia runtime: %w", err)
	}
	return nil
}

// setupCluster создает и настраивает кластер
func (m *Manager) setupCluster(ctx context.Context) error {
	// Проверка существующего кластера
	if !m.noRecreate {
		cmd := exec.Command("kind", "delete", "cluster", "--name", m.clusterName)
		cmd.Run() // Игнорируем ошибку, если кластер не существует
	}

	// Создание нового кластера
	cmd := exec.Command("kind", "create", "cluster",
		"--name", m.clusterName,
		"--config", filepath.Join(m.workDir, "kind-config.yaml"))
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to create cluster: %w", err)
	}

	// Ожидание готовности узлов
	timeout := time.After(5 * time.Minute)
	ticker := time.NewTicker(10 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-timeout:
			return fmt.Errorf("timeout waiting for nodes")
		case <-ticker.C:
			if m.checkNodesReady() {
				return nil
			}
		}
	}
}

// checkNodesReady проверяет готовность узлов
func (m *Manager) checkNodesReady() bool {
	cmd := exec.Command("kubectl", "wait", "--for=condition=Ready", "nodes", "--all", "--timeout=10s")
	return cmd.Run() == nil
}

// generateConfig генерирует конфигурацию кластера
func (m *Manager) generateConfig() error {
	// Обнаружение системных параметров
	sysInfo, err := system.Detect()
	if err != nil {
		return fmt.Errorf("failed to detect system info: %w", err)
	}

	// Генерация конфигурации
	config := sysInfo.GenerateKindConfig()

	// Запись конфигурации в файл
	configPath := filepath.Join(m.workDir, "kind-config.yaml")
	return os.WriteFile(configPath, []byte(config), 0644)
}


// Cleanup выполняет очистку ресурсов
func (m *Manager) Cleanup() error {
	if m.noRemove {
		return nil
	}

	if err := exec.Command("kind", "delete", "cluster", "--name", m.clusterName).Run(); err != nil {
		return fmt.Errorf("failed to delete cluster: %w", err)
	}

	return nil
}