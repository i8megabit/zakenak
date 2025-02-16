// Copyright (c) 2024 Mikhail Eberil
//
// This file is part of Zakenak project and is released under the terms of the
// MIT License. See LICENSE file in the project root for full license information.

package main

import (
    "os"
    
    "github.com/spf13/cobra"
)

var (
    kubeconfig string

    namespace  string
    configPath string
)

func main() {
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

func initKubeClient() (*kubernetes.Clientset, error) {
    config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
    if err != nil {
        return nil, err
    }
    return kubernetes.NewForConfig(config)
}

func runConverge() error {
    // TODO: Имплементация конвергенции
    return nil
}

func runBuild() error {
    // TODO: Имплементация сборки
    return nil
}

func runDeploy() error {
    // TODO: Имплементация деплоя
    return nil
}

func runClean() error {
    // TODO: Имплементация очистки
    return nil
}