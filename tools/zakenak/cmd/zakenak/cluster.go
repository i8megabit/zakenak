/*
 * Copyright (c) 2024 Mikhail Eberil
 * 
 * This file is part of Ƶakenak, a GitOps deployment tool.
 * 
 * Ƶakenak is free software: you can redistribute it and/or modify
 * it under the terms of the MIT License with Trademark Protection.
 * 
 * Ƶakenak is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * MIT License for more details.
 * 
 * The name "Ƶakenak" and associated branding are trademarks of @eberil
 * and may not be used without express written permission.
 */

package main

import (
    "github.com/spf13/cobra"
    "github.com/i8megabit/zakenak/pkg/kind"
)

func newClusterCmd() *cobra.Command {
    cmd := &cobra.Command{
        Use:   "cluster",
        Short: "Управление Kind кластером",
    }

    cmd.AddCommand(
        newClusterCreateCmd(),
        newClusterDeleteCmd(),
    )

    return cmd
}

func newClusterCreateCmd() *cobra.Command {
    var configPath string
    var gpuEnabled bool

    cmd := &cobra.Command{
        Use:   "create",
        Short: "Создать новый Kind кластер",
        RunE: func(cmd *cobra.Command, args []string) error {
            cfg := kind.DefaultConfig()
            cfg.GPUEnabled = gpuEnabled

            if err := cfg.GenerateConfig(configPath); err != nil {
                return err
            }

            manager := kind.NewManager(configPath)
            return manager.CreateCluster(cmd.Context())
        },
    }

    cmd.Flags().StringVar(&configPath, "config", "kind-config.yaml", "путь к конфигурации Kind")
    cmd.Flags().BoolVar(&gpuEnabled, "gpu", true, "включить поддержку GPU")

    return cmd
}

func newClusterDeleteCmd() *cobra.Command {
    return &cobra.Command{
        Use:   "delete",
        Short: "Удалить Kind кластер",
        RunE: func(cmd *cobra.Command, args []string) error {
            manager := kind.NewManager("")
            return manager.deleteExistingCluster(cmd.Context())
        },
    }
}