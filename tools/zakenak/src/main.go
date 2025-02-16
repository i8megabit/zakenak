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
	"github.com/i8meg/zakenak/pkg/config"
	"github.com/i8meg/zakenak/pkg/state"
	"github.com/i8meg/zakenak/pkg/helm"
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
	)
}

var rootCmd = &cobra.Command{
	Use:   "zakenak",
	Short: "Zakenak - элегантный инструмент для GitOps и деплоя",
	Long: `Zakenak - карманный инструмент для ежедневной Helm-оркестрации 
однонодового Kind кластера Kubernetes с поддержкой GPU.`,
}
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
	"github.com/i8meg/zakenak/pkg/config"
	"github.com/i8meg/zakenak/pkg/state"
	"github.com/i8meg/zakenak/pkg/helm"
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
	)
}

var rootCmd = &cobra.Command{
	Use:   "zakenak",
	Short: "Zakenak - элегантный инструмент для GitOps и деплоя",
	Long: `Zakenak - карманный инструмент для ежедневной Helm-оркестрации 
однонодового Kind кластера Kubernetes с поддержкой GPU.`,
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

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Ошибка: %v\n", err)
		os.Exit(1)
	}
}

func runInit() error {
	ctx := context.Background()
	
	// Инициализация кластера
	if err := initCluster(ctx); err != nil {
		return fmt.Errorf("ошибка инициализации кластера: %w", err)
	}
	
	// Установка базовых компонентов
	if err := setupBaseComponents(ctx); err != nil {
		return fmt.Errorf("ошибка установки компонентов: %w", err)
	}
	
	return nil
}

func runUp() error {
	ctx := context.Background()
	
	// Восстановление состояния
	state, err := loadState()
	if err != nil {
		return fmt.Errorf("ошибка загрузки состояния: %w", err)
	}
	
	// Запуск сервисов
	if err := startServices(ctx, state); err != nil {
		return fmt.Errorf("ошибка запуска сервисов: %w", err)
	}
	
	return nil
}

func runDown() error {
	ctx := context.Background()
	
	// Сохранение состояния
	if err := saveState(); err != nil {
		return fmt.Errorf("ошибка сохранения состояния: %w", err)
	}
	
	// Остановка кластера
	if err := stopCluster(ctx); err != nil {
		return fmt.Errorf("ошибка остановки кластера: %w", err)
	}
	
	return nil
}

func runStatus() error {
	ctx := context.Background()
	
	// Получение статуса компонентов
	status, err := getStatus(ctx)
	if err != nil {
		return fmt.Errorf("ошибка получения статуса: %w", err)
	}
	
	// Вывод статуса
	printStatus(status)
	
	return nil
}