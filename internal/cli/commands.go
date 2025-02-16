/*
 * Copyright (c) 2024 Mikhail Eberil
 *
 * This file is part of Zakenak project and is released under the terms of the
 * MIT License. See LICENSE file in the project root for full license information.
 */

package cli

import (
	"github.com/spf13/cobra"
)

// NewConvergeCmd создает команду converge
func NewConvergeCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "converge",
		Short: "Привести состояние кластера к желаемому",
		RunE: func(cmd *cobra.Command, args []string) error {
			return runConverge()
		},
	}
	return cmd
}

// NewBuildCmd создает команду build
func NewBuildCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "build",
		Short: "Собрать Docker образы",
		RunE: func(cmd *cobra.Command, args []string) error {
			return runBuild()
		},
	}
	return cmd
}

// NewDeployCmd создает команду deploy
func NewDeployCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "deploy",
		Short: "Развернуть приложение в кластере",
		RunE: func(cmd *cobra.Command, args []string) error {
			return runDeploy()
		},
	}
	return cmd
}

// NewCleanCmd создает команду clean
func NewCleanCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "clean",
		Short: "Очистить временные файлы и ресурсы",
		RunE: func(cmd *cobra.Command, args []string) error {
			return runClean()
		},
	}
	return cmd
}