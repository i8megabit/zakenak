/*
 * Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
 * 
 * This file is part of Ƶakenak™® project.
 * https://github.com/i8megabit/zakenak
 *
 * This program is free software and is released under the terms of the MIT License.
 * See LICENSE.md file in the project root for full license information.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 *
 * TRADEMARK NOTICE:
 * Ƶakenak™® and the Ƶakenak logo are registered trademarks of Mikhail Eberil.
 * All rights reserved. The Ƶakenak trademark and brand may not be used in any way 
 * without express written permission from the trademark owner.
 */

package main

import (
    "context"
    "fmt"
    "path/filepath"
    "github.com/i8megabit/zakenak/pkg/config"
    "github.com/i8megabit/zakenak/pkg/helm"
    "k8s.io/client-go/kubernetes"
    corev1 "k8s.io/api/core/v1"
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    apierrors "k8s.io/apimachinery/pkg/api/errors"
)

// deployHandler handles deployment operations
func deployHandler(client *kubernetes.Clientset, cfg *config.Config) error {
    // Создание namespace если не существует
    if err := ensureNamespace(client, cfg.Deploy.Namespace); err != nil {
        return fmt.Errorf("failed to ensure namespace: %w", err)
    }

    // Развертывание каждого чарта
    if err := deployChart(client, cfg, cfg.Deploy.ChartPath); err != nil {
        return fmt.Errorf("failed to deploy chart %s: %w", cfg.Deploy.ChartPath, err)
    }


    return nil
}

// ensureNamespace creates namespace if it doesn't exist
func ensureNamespace(client *kubernetes.Clientset, namespace string) error {
    ns := &corev1.Namespace{
        ObjectMeta: metav1.ObjectMeta{
            Name: namespace,
        },
    }
    
    _, err := client.CoreV1().Namespaces().Create(context.Background(), ns, metav1.CreateOptions{})
    if err != nil && !apierrors.IsAlreadyExists(err) {
        return fmt.Errorf("failed to create namespace: %w", err)
    }
    
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
