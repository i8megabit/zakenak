// Copyright (c) 2024 ƵakӖnak™®
// Author: @ӗberil
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
	"github.com/i8meg/zakenak/pkg/converge"
	"github.com/i8meg/zakenak/pkg/build"
)

var (
	Version    = "1.0.0"
	namespace  string
	debug      bool
	configFile string
	gpuEnabled bool
	chartPath  string
	values     []string
)

func init() {
	rootCmd.PersistentFlags().StringVarP(&namespace, "namespace", "n", "prod", "Целевой namespace")
	rootCmd.PersistentFlags().BoolVarP(&debug, "debug", "d", false, "Включить отладочный режим")
	rootCmd.PersistentFlags().StringVarP(&configFile, "config", "c", "zakenak.yaml", "Путь к конфигурационному файлу")
	rootCmd.PersistentFlags().BoolVarP(&gpuEnabled, "gpu", "g", false, "Включить поддержку GPU")

	deployCmd.Flags().StringVarP(&chartPath, "chart", "p", "", "Путь к Helm чарту")
	deployCmd.Flags().StringArrayVarP(&values, "values", "f", []string{}, "Файлы values.yaml")

	rootCmd.AddCommand(deployCmd)
	rootCmd.AddCommand(buildCmd)
	rootCmd.AddCommand(convergeCmd)
	rootCmd.AddCommand(versionCmd)
}

var rootCmd = &cobra.Command{
	Use:   "zakenak",
	Short: "ƵakӖnak™® - инструмент для управления Kubernetes кластером",
	Long: `ƵakӖnak™® - карманный инструмент для ежедневной Helm-оркестрации 
однонодового Kind кластера Kubernetes с поддержкой GPU.`,
	Run: func(cmd *cobra.Command, args []string) {
		cmd.Help()
	},
}

var deployCmd = &cobra.Command{
	Use:   "deploy [chart]",
	Short: "Развернуть чарт или все чарты",
	Run: func(cmd *cobra.Command, args []string) {
		if err := runDeploy(args...); err != nil {
			fmt.Fprintf(os.Stderr, "Ошибка: %v\n", err)
			os.Exit(1)
		}
	},
}

var buildCmd = &cobra.Command{
	Use:   "build",
	Short: "Собрать все необходимые образы",
	Run: func(cmd *cobra.Command, args []string) {
		if err := runBuild(); err != nil {
			fmt.Fprintf(os.Stderr, "Ошибка: %v\n", err)
			os.Exit(1)
		}
	},
}

var convergeCmd = &cobra.Command{
	Use:   "converge",
	Short: "Запустить конвергенцию состояния",
	Run: func(cmd *cobra.Command, args []string) {
		if err := runConverge(); err != nil {
			fmt.Fprintf(os.Stderr, "Ошибка: %v\n", err)
			os.Exit(1)
		}
	},
}

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Показать версию",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("ƵakӖnak™® версия %s\n", Version)
	},
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func runDeploy(args ...string) error {
	// TODO: Имплементация деплоя
	return nil
}

func runBuild() error {
	// TODO: Имплементация сборки
	return nil
}

func runConverge() error {
	// TODO: Имплементация конвергенции
	return nil
}