/* 
Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
This code is part of Zakenak project and is released under MIT License.
See LICENSE file in the project root for full license information.
*/

package main

import (
    "fmt"
    "os"

    "github.com/i8megabit/zakenak/pkg/banner"
)

// Version contains the application version, set during build
var Version = "dev"


func main() {
    banner.PrintZakenak()

    if len(os.Args) > 1 {
        switch os.Args[1] {
        case "--version":
            fmt.Printf("zakenak version %s\n", Version)
            return
        case "--help":
            fmt.Println("Usage: zakenak [command] [options]")
            fmt.Println("\nCommands:")
            fmt.Println("  --version     Show version information")
            fmt.Println("  --help        Show this help message")
            fmt.Println("  --config      Specify configuration file")
            return
        }
    }

    // Default behavior when no arguments are provided
    fmt.Println("Zakenak - Kubernetes Cluster Management Tool")
    fmt.Println("Use --help for usage information")
}


func newConvergeCmd() *cobra.Command {
    cmd := &cobra.Command{
        Use:   "converge",
        Short: "Привести состояние кластера к желаемому",
        RunE: func(cmd *cobra.Command, args []string) error {
            return runConverge()
        },
    }
    return cmd
}

func newBuildCmd() *cobra.Command {
    cmd := &cobra.Command{
        Use:   "build",
        Short: "Собрать Docker образы",
        RunE: func(cmd *cobra.Command, args []string) error {
            return runBuild()
        },
    }
    return cmd
}

func newDeployCmd() *cobra.Command {
    cmd := &cobra.Command{
        Use:   "deploy",
        Short: "Развернуть в Kubernetes",
        RunE: func(cmd *cobra.Command, args []string) error {
            return runDeploy()
        },
    }
    return cmd
}

func newCleanCmd() *cobra.Command {
    cmd := &cobra.Command{
        Use:   "clean",
        Short: "Очистить ресурсы",
        RunE: func(cmd *cobra.Command, args []string) error {
            return runClean()
        },
    }
    return cmd
}

func createKubernetesClient(kubeconfig string) (*kubernetes.Clientset, error) {
    config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
    if err != nil {
        return nil, fmt.Errorf("error building kubeconfig: %w", err)
    }

    clientset, err := kubernetes.NewForConfig(config)
    if err != nil {
        return nil, fmt.Errorf("error creating kubernetes client: %w", err)
    }

    return clientset, nil
}

func runConverge() error {
    banner.PrintDeploy()
    ctx := context.Background()
    
    // Создаем и настраиваем Git manager в начале
    gitManager := git.NewManager("/workspace")
    if err := gitManager.EnsureMainBranch(); err != nil {
        log.Printf("Git initialization failed with details: %v", err)
        return fmt.Errorf("failed to ensure main branch: %w", err)
    }
    
    // Создаем клиент Kubernetes
    clientset, err := createKubernetesClient(kubeconfig)
    if err != nil {
        return fmt.Errorf("error creating kubernetes client: %w", err)
    }

    // Загружаем конфигурацию из файла
    cfg, err := config.LoadConfig(configPath)
    if err != nil {
        return fmt.Errorf("error loading config: %w", err)
    }

    // Создаем менеджер состояния
    stateManager := state.NewFileStateManager(filepath.Join(os.TempDir(), "zakenak-state.json"))

    // Создаем менеджер конвергенции
    manager := converge.NewManager(clientset, cfg, stateManager)
    
    // Запускаем процесс конвергенции
    if err := manager.Converge(ctx); err != nil {
        banner.PrintError()
        // Восстанавливаем ветку даже при ошибке
        if restoreErr := gitManager.RestoreOriginalBranch(); restoreErr != nil {
            log.Printf("Warning: failed to restore original git branch: %v", restoreErr)
        }
        return fmt.Errorf("convergence failed: %w", err)
    }

    banner.PrintSuccess()

    // Восстанавливаем исходную ветку Git и удаляем main после успешной конвергенции
    if err := gitManager.RestoreOriginalBranch(); err != nil {
        log.Printf("Warning: failed to restore original git branch: %v", err)
    }

    return nil
}

func runBuild() error {
    // Загружаем конфигурацию
    cfg, err := config.LoadConfig(configPath)
    if err != nil {
        return fmt.Errorf("error loading config: %w", err)
    }

    // Создаем билдер
    builder := build.NewBuilder(&cfg.Build)
    
    // Настраиваем билдер
    if err := builder.Configure(); err != nil {
        return fmt.Errorf("builder configuration failed: %w", err)
    }

    return nil
}

func runDeploy() error {
    ctx := context.Background()
    
    // Создаем клиент Kubernetes
    clientset, err := createKubernetesClient(kubeconfig)
    if err != nil {
        return fmt.Errorf("error creating kubernetes client: %w", err)
    }

    // Загружаем конфигурацию
    cfg, err := config.LoadConfig(configPath)
    if err != nil {
        return fmt.Errorf("error loading config: %w", err)
    }

    // Создаем менеджер состояния
    stateManager := state.NewFileStateManager(filepath.Join(os.TempDir(), "zakenak-state.json"))

    // Создаем менеджер конвергенции для деплоя
    manager := converge.NewManager(clientset, cfg, stateManager)

    
    // Запускаем процесс деплоя
    if err := manager.Deploy(ctx); err != nil {
        return fmt.Errorf("deployment failed: %w", err)
    }

    return nil
}

func runClean() error {
    // TODO: Имплементация очистки
    return nil
}

func newStatusCmd() *cobra.Command {
    cmd := &cobra.Command{
        Use:   "status",
        Short: "Проверить статус развернутых компонентов",
        RunE: func(cmd *cobra.Command, args []string) error {
            return runStatus()
        },
    }
    return cmd
}

func newSetupCmd() *cobra.Command {
    var (
        noRemove    bool
        noGenerate  bool
        noRecreate  bool
        workDir     string
    )

    cmd := &cobra.Command{
        Use:   "setup",
        Short: "Настройка кластера Kubernetes",
        RunE: func(cmd *cobra.Command, args []string) error {
            if workDir == "" {
                var err error
                workDir, err = os.Getwd()
                if err != nil {
                    return fmt.Errorf("failed to get working directory: %w", err)
                }
            }

            manager := cluster.NewManager(workDir,
                cluster.WithNoRemove(noRemove),
                cluster.WithNoGenerate(noGenerate),
                cluster.WithNoRecreate(noRecreate))

            if err := manager.Setup(cmd.Context()); err != nil {
                banner.PrintError()
                return fmt.Errorf("setup failed: %w", err)
            }

            banner.PrintSuccess()
            return nil
        },
    }

    cmd.Flags().BoolVar(&noRemove, "no-remove", false, "не удалять ресурсы при ошибке")
    cmd.Flags().BoolVar(&noGenerate, "no-generate", false, "не генерировать конфигурацию")
    cmd.Flags().BoolVar(&noRecreate, "no-recreate", false, "не пересоздавать существующий кластер")
    cmd.Flags().StringVar(&workDir, "workdir", "", "рабочая директория")

    return cmd
}




func runStatus() error {
    banner.PrintZakenak()

    // Проверка статуса компонентов в namespace prod
    components := []string{
        "deployment/cert-manager",
        "deployment/local-ca", 
        "deployment/ollama",
        "deployment/open-webui",
        "deployment/sidecar-injector",
    }

    fmt.Println("\nПроверка статуса компонентов...")

    for _, component := range components {
        // Проверяем статус через kubectl
        if err := exec.Command("kubectl", "get", component, "-n", "prod").Run(); err != nil {
            banner.PrintError()
            return fmt.Errorf("компонент %s не готов: %v", component, err)
        }
        fmt.Printf("✓ %s работает\n", component)
    }

    banner.PrintSuccess()
    return nil
}