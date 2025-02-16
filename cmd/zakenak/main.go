/*
 * Copyright (c) 2024 Mikhail Eberil
 *
 * This file is part of Zakenak project and is released under the terms of the
 * MIT License. See LICENSE file in the project root for full license information.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 *
 * The name "Zakenak" and associated branding are trademarks of @eberil
 * and may not be used without express written permission.
 */

package main

import (
	"fmt"
	"os"
	
	"github.com/spf13/cobra"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
	
	"github.com/i8meg/zakenak/internal/app"
	"github.com/i8meg/zakenak/internal/config"
	"github.com/i8meg/zakenak/internal/gpu"
	"github.com/i8meg/zakenak/pkg/banner"
)

var (
	Version = "1.3.1"
	kubeconfig string
	namespace  string
	configPath string
)

func main() {
	// Отображение баннера
	banner.Show()

	// Создание корневой команды
	rootCmd := &cobra.Command{
		Use:   "zakenak",
		Short: "Zakenak - GitOps-драккар для оркестрации Kubernetes",
		PersistentPreRun: func(cmd *cobra.Command, args []string) {
			// Загрузка конфигурации
			cfg, err := config.Load()
			if err != nil {
				fmt.Printf("Error loading config: %v\n", err)
				os.Exit(1)
			}

			// Проверка GPU
			if cfg.GPU.Enabled {
				if err := gpu.CheckRequirements(); err != nil {
					fmt.Printf("GPU requirements not met: %v\n", err)
					os.Exit(1)
				}
			}
		},
	}

	// Добавление глобальных флагов
	rootCmd.PersistentFlags().StringVar(&kubeconfig, "kubeconfig", "", "путь к kubeconfig")
	rootCmd.PersistentFlags().StringVar(&namespace, "namespace", "", "целевой namespace")
	rootCmd.PersistentFlags().StringVar(&configPath, "config", "zakenak.yaml", "путь к конфигурации")

	// Добавление команд
	rootCmd.AddCommand(
		newConvergeCmd(),
		newBuildCmd(),
		newDeployCmd(),
		newCleanCmd(),
	)

	// Запуск приложения
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Ошибка: %v\n", err)
		os.Exit(1)
	}
}