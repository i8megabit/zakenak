// Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
//
// This file is part of Zakenak project and is released under the terms of the
// MIT License. See LICENSE file in the project root for full license information.

package main

import (
    "context"
    "fmt"
    "os"
    "path/filepath"
    
    "github.com/spf13/cobra"
    "k8s.io/client-go/kubernetes"
    "k8s.io/client-go/tools/clientcmd"
    "github.com/i8megabit/zakenak/pkg/config"
    "github.com/i8megabit/zakenak/pkg/converge"
    "github.com/i8megabit/zakenak/pkg/build"
    "github.com/i8megabit/zakenak/pkg/state"
    "github.com/i8megabit/zakenak/pkg/banner"
)

var (
    kubeconfig string

    namespace  string
    configPath string
)

func main() {
    banner.PrintZakenak()
    
    rootCmd := &cobra.Command{
        Use:   "zakenak",
        Short: "Zakenak - элегантный инструмент для GitOps и деплоя",
    }

    rootCmd.PersistentFlags().StringVar(&kubeconfig, "kubeconfig", "", "путь к kubeconfig")
    rootCmd.PersistentFlags().StringVar(&namespace, "namespace", "", "целевой namespace")
    rootCmd.PersistentFlags().StringVar(&configPath, "config", "zakenak.yaml", "путь к конфигурации")

    rootCmd.AddCommand(
        newConvergeCmd(),
        newBuildCmd(),
        newDeployCmd(),
        newCleanCmd(),
    )

    if err := rootCmd.Execute(); err != nil {
        os.Exit(1)
    }

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
        return fmt.Errorf("convergence failed: %w", err)
    }

    banner.PrintSuccess()
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