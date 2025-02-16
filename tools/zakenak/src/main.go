// Copyright (c) 2024 Zakenak
// Author: @eberil
// License: MIT with Trademark Protection

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
)

var (
	Version    = "1.0.0"
	kubeconfig string
	namespace  string
	debug      bool
	configFile string
	gpuEnabled bool
)

func init() {
	rootCmd.PersistentFlags().StringVar(&kubeconfig, "kubeconfig", "", "путь к kubeconfig")
	rootCmd.PersistentFlags().StringVarP(&namespace, "namespace", "n", "prod", "целевой namespace")
	rootCmd.PersistentFlags().BoolVarP(&debug, "debug", "d", false, "включить отладочный режим")
	rootCmd.PersistentFlags().StringVarP(&configFile, "config", "c", "zakenak.yaml", "путь к конфигурации")
	rootCmd.PersistentFlags().BoolVarP(&gpuEnabled, "gpu", "g", true, "включить поддержку GPU")

	rootCmd.AddCommand(
		newInitCmd(),
		newUpCmd(),
		newDownCmd(),
		newStatusCmd(),
		newDeployCmd(),
	)
}

var rootCmd = &cobra.Command{
	Use:   "zakenak",
	Short: "Zakenak - элегантный инструмент для GitOps и деплоя",
	Long: `Zakenak - карманный инструмент для ежедневной Helm-оркестрации 
однонодового Kind кластера Kubernetes с поддержкой GPU.`,
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Ошибка: %v\n", err)
		os.Exit(1)
	}
}


func newInitCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "init",
		Short: "Инициализировать кластер и базовые компоненты",
		RunE: func(cmd *cobra.Command, args []string) error {
			return runInit()
		},
	}
}

func newUpCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "up",
		Short: "Поднять кластер и все сервисы",
		RunE: func(cmd *cobra.Command, args []string) error {
			return runUp()
		},
	}
}

func newDownCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "down",
		Short: "Остановить кластер с сохранением данных",
		RunE: func(cmd *cobra.Command, args []string) error {
			return runDown()
		},
	}
}

func newStatusCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "status",
		Short: "Показать статус компонентов",
		RunE: func(cmd *cobra.Command, args []string) error {
			return runStatus()
		},
	}
}

func runInit() error {
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

	// Создаем менеджер конвергенции
	manager := converge.NewManager(clientset, cfg)
	
	// Запускаем процесс инициализации
	if err := manager.Initialize(ctx); err != nil {
		return fmt.Errorf("initialization failed: %w", err)
	}

	return nil
}


func createKubernetesClient(kubeconfigPath string) (*kubernetes.Clientset, error) {
	config, err := clientcmd.BuildConfigFromFlags("", kubeconfigPath)
	if err != nil {
		return nil, fmt.Errorf("error building kubeconfig: %w", err)
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		return nil, fmt.Errorf("error creating kubernetes client: %w", err)
	}

	return clientset, nil
}