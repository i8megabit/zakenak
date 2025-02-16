package main

import (
	"context"
	"fmt"
	"os"
	"github.com/spf13/cobra"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
	"github.com/i8megabit/zakenak/pkg/config"
	"github.com/i8megabit/zakenak/pkg/converge"
	"github.com/i8megabit/zakenak/pkg/state"
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
	)

	if err := rootCmd.Execute(); err != nil {
		os.Exit(1)
	}
}



func newConvergeCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "converge",
		Short: "Запустить процесс конвергенции",
		RunE: func(cmd *cobra.Command, args []string) error {
			return runConverge()
		},
	}
}

func newBuildCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "build",
		Short: "Собрать компоненты",
		RunE: func(cmd *cobra.Command, args []string) error {
			return fmt.Errorf("not implemented")
		},
	}
}

func runConverge() error {
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
	stateManager := state.NewFileStateManager("zakenak-state.json")

	// Создаем менеджер конвергенции
	manager := converge.NewManager(clientset, cfg, stateManager)
	
	// Запускаем процесс конвергенции
	if err := manager.Converge(ctx); err != nil {
		return fmt.Errorf("convergence failed: %w", err)
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