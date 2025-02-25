package main

import (
    "github.com/spf13/cobra"
    "github.com/i8megabit/zakenak/pkg/cluster"
)

func newClusterCmd() *cobra.Command {
    cmd := &cobra.Command{
        Use:   "cluster",
        Short: "Управление Docker Desktop Kubernetes",
    }

    cmd.AddCommand(
        newClusterVerifyCmd(),
        newClusterEnableCmd(),
    )

    return cmd
}

func newClusterVerifyCmd() *cobra.Command {
    var clusterName string

    cmd := &cobra.Command{
        Use:   "verify",
        Short: "Проверить состояние Docker Desktop Kubernetes",
        RunE: func(cmd *cobra.Command, args []string) error {
            manager := cluster.NewManager(clusterName)
            if err := manager.VerifyCluster(cmd.Context()); err != nil {
                return err
            }
            return manager.WaitForCluster(cmd.Context())
        },
    }

    cmd.Flags().StringVar(&clusterName, "name", "docker-desktop", "имя кластера")
    return cmd
}

func newClusterEnableCmd() *cobra.Command {
    var clusterName string
    
    cmd := &cobra.Command{
        Use:   "enable",
        Short: "Включить Docker Desktop Kubernetes",
        RunE: func(cmd *cobra.Command, args []string) error {
            manager := cluster.NewManager(clusterName)
            return manager.EnableKubernetes(cmd.Context())
        },
    }

    cmd.Flags().StringVar(&clusterName, "name", "docker-desktop", "имя кластера")
    return cmd
}