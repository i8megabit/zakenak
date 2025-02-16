package converge

import (
    "context"
    "fmt"
    "os/exec"
    "time"
    "github.com/i8megabit/zakenak/pkg/config"
    "github.com/i8megabit/zakenak/pkg/state"
    "k8s.io/client-go/kubernetes"
)

// Manager управляет процессом конвергенции состояния
type Manager struct {
    client    *kubernetes.Clientset
    config    *config.Config
    state     *state.FileStateManager
    namespace string
}

// NewManager создает новый менеджер конвергенции
func NewManager(client *kubernetes.Clientset, cfg *config.Config, stateManager *state.FileStateManager) *Manager {
    return &Manager{
        client:    client,
        config:    cfg,
        state:     stateManager,
        namespace: cfg.Deploy.Namespace,
    }
}

// Converge приводит текущее состояние к желаемому
func (m *Manager) Converge(ctx context.Context) error {
    // Проверка состояния GPU
    if err := m.checkGPUState(ctx); err != nil {
        return fmt.Errorf("gpu check failed: %w", err)
    }

    // Проверка состояния Git
    if err := m.checkGitState(ctx); err != nil {
        return fmt.Errorf("git check failed: %w", err)
    }

    // Сборка образов если необходимо
    if err := m.buildImages(ctx); err != nil {
        return fmt.Errorf("build failed: %w", err)
    }

    // Развертывание в кластер
    if err := m.deploy(ctx); err != nil {
        return fmt.Errorf("deploy failed: %w", err)
    }

    return nil
}

// checkGPUState проверяет состояние GPU
func (m *Manager) checkGPUState(ctx context.Context) error {
    // Проверка наличия nvidia-smi
    cmd := exec.CommandContext(ctx, "nvidia-smi")
    if err := cmd.Run(); err != nil {
        return fmt.Errorf("NVIDIA GPU not available: %w", err)
    }

    // Обновление состояния GPU
    return m.state.Update(func(s *state.State) error {
        s.GPU.Driver = "535.104.05" // TODO: Получать динамически
        s.GPU.Enabled = true
        return nil
    })
}

// checkGitState проверяет состояние Git репозитория
func (m *Manager) checkGitState(ctx context.Context) error {
    // Проверка текущей ветки
    cmd := exec.CommandContext(ctx, "git", "rev-parse", "--abbrev-ref", "HEAD")
    branch, err := cmd.Output()
    if err != nil {
        return fmt.Errorf("failed to get current branch: %w", err)
    }

    if string(branch) != m.config.Git.Branch+"\n" {
        return fmt.Errorf("not on the required branch: %s", m.config.Git.Branch)
    }

    return nil
}

// buildImages собирает Docker образы с поддержкой GPU
func (m *Manager) buildImages(ctx context.Context) error {
    if !m.config.Build.GPU.Enabled {
        return nil
    }

    buildArgs := []string{
        "build",
        "--build-arg", "CUDA_VERSION=12.8.0",
        "--build-arg", "GPU_ENABLED=true",
        "-f", m.config.Build.Dockerfile,
        "-t", fmt.Sprintf("%s/%s:%s",
            m.config.Registry.URL,
            m.config.Project,
            m.config.Build.Args["VERSION"],
        ),
        m.config.Build.Context,
    }

    cmd := exec.CommandContext(ctx, "docker", buildArgs...)
    return cmd.Run()
}

// deploy выполняет развертывание в кластер
func (m *Manager) deploy(ctx context.Context) error {
    // Обновление состояния
    if err := m.state.Update(func(s *state.State) error {
        s.Status.Phase = state.PhaseDeploying
        s.Status.LastTransition = time.Now()
        return nil
    }); err != nil {
        return fmt.Errorf("failed to update state: %w", err)
    }

    // Развертывание каждого чарта
    for _, chartPath := range m.config.Deploy.Charts {
        if err := m.deployChart(ctx, chartPath); err != nil {
            return fmt.Errorf("failed to deploy chart %s: %w", chartPath, err)
        }
    }

    return nil
}

// deployChart разворачивает отдельный Helm чарт
func (m *Manager) deployChart(ctx context.Context, chartPath string) error {
    args := []string{
        "upgrade",
        "--install",
        "--namespace", m.namespace,
    }

    // Добавление values файлов
    for _, valuesFile := range m.config.Deploy.Values {
        args = append(args, "-f", valuesFile)
    }

    // Добавление GPU-специфичных значений если включено
    if m.config.Build.GPU.Enabled {
        args = append(args,
            "--set", fmt.Sprintf("gpu.enabled=%t", true),
            "--set", fmt.Sprintf("gpu.memory=%s", m.config.Build.GPU.Memory),
        )
    }

    cmd := exec.CommandContext(ctx, "helm", args...)
    return cmd.Run()
}