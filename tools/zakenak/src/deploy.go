package main

import (
    "context"
    "fmt"
    "path/filepath"
    "github.com/i8megabit/zakenak/pkg/config"
    "github.com/i8megabit/zakenak/pkg/helm"
    "k8s.io/client-go/kubernetes"
)

// deployHandler handles deployment operations
func deployHandler(client *kubernetes.Clientset, cfg *config.Config) error {
    // Создание namespace если не существует
    if err := ensureNamespace(client, cfg.Deploy.Namespace); err != nil {
        return fmt.Errorf("failed to ensure namespace: %w", err)
    }

    // Развертывание каждого чарта
    for _, chartPath := range cfg.Deploy.Charts {
        if err := deployChart(client, cfg, chartPath); err != nil {
            return fmt.Errorf("failed to deploy chart %s: %w", chartPath, err)
        }
    }

    return nil
}

// ensureNamespace creates namespace if it doesn't exist
func ensureNamespace(client *kubernetes.Clientset, namespace string) error {
    // Implementation for namespace creation
    return nil
}

// deployChart deploys a single Helm chart
func deployChart(client *kubernetes.Clientset, cfg *config.Config, chartPath string) error {
    helmClient := helm.NewClient()
    
    // Get absolute path to chart
    absPath, err := filepath.Abs(chartPath)
    if err != nil {
        return fmt.Errorf("failed to get absolute path: %w", err)
    }

    // Validate chart
    if err := helmClient.ValidateChart(absPath); err != nil {
        return fmt.Errorf("chart validation failed: %w", err)
    }

    return nil
}
