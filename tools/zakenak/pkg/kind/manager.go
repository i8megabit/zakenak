/*
 * Copyright (c)  2025 Mikhail Eberil
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
 * The name "Ƶakenak" and associated branding are  * Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
 * 
 * This file is part of Zakenak project.
 * https://github.com/i8megabit/zakenak
 *
 * This program is free software and is released under the terms of the MIT License.
 * See LICENSE.md file in the project root for full license information.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.of @eberil
 * and may not be used without express written permission.
 */

package kind

import (
    "context"
    "fmt"
    "os"
    "os/exec"
    "time"
)


// Manager управляет Kind кластером
type Manager struct {
    name       string
    configPath string
    nodeImage  string
}

// NewManager создает новый менеджер Kind
func NewManager(name string, configPath string) *Manager {
    return &Manager{
        name:       name,
        configPath: configPath,
        nodeImage:  "kindest/node:v1.27.3",
    }
}

// DeleteExistingCluster удаляет существующий кластер
func (m *Manager) DeleteExistingCluster(ctx context.Context) error {
    cmd := exec.CommandContext(ctx, "kind", "get", "clusters")
    output, err := cmd.Output()
    if err != nil {
        return fmt.Errorf("failed to get clusters: %w", err)
    }

    if string(output) != "" {
        cmd = exec.CommandContext(ctx, "kind", "delete", "cluster", "--name", m.name)
        if err := cmd.Run(); err != nil {
            return fmt.Errorf("failed to delete cluster: %w", err)
        }
        time.Sleep(5 * time.Second)
    }

    return nil
}

// CreateCluster создает новый кластер
func (m *Manager) CreateCluster(ctx context.Context) error {
    // Проверка существующего кластера
    if err := m.deleteExistingCluster(ctx); err != nil {
        return fmt.Errorf("failed to delete existing cluster: %w", err)
    }

    // Предварительная загрузка образов
    if err := m.pullRequiredImages(ctx); err != nil {
        return fmt.Errorf("failed to pull images: %w", err)
    }

    // Создание кластера
    cmd := exec.CommandContext(ctx, "kind", "create", "cluster",
        "--config", m.configPath,
        "--image", m.nodeImage)
    cmd.Stdout = os.Stdout
    cmd.Stderr = os.Stderr

    if err := cmd.Run(); err != nil {
        return fmt.Errorf("failed to create cluster: %w", err)
    }

    // Ожидание готовности узлов
    return m.waitForNodes(ctx)
}

// deleteExistingCluster удаляет существующий кластер если он есть
func (m *Manager) deleteExistingCluster(ctx context.Context) error {
    cmd := exec.CommandContext(ctx, "kind", "get", "clusters")
    output, err := cmd.Output()
    if err != nil {
        return fmt.Errorf("failed to get clusters: %w", err)
    }

    if string(output) != "" {
        cmd = exec.CommandContext(ctx, "kind", "delete", "cluster")
        if err := cmd.Run(); err != nil {
            return fmt.Errorf("failed to delete cluster: %w", err)
        }
        time.Sleep(5 * time.Second)
    }

    return nil
}

// pullRequiredImages загружает необходимые образы
func (m *Manager) pullRequiredImages(ctx context.Context) error {
    images := []string{
        m.nodeImage,
        "nginx:1.25.3",
        "quay.io/jetstack/cert-manager-controller:v1.12.0",
    }

    for _, image := range images {
        cmd := exec.CommandContext(ctx, "docker", "pull", image)
        cmd.Stdout = os.Stdout
        cmd.Stderr = os.Stderr
        if err := cmd.Run(); err != nil {
            return fmt.Errorf("failed to pull image %s: %w", image, err)
        }
    }

    return nil
}

// waitForNodes ожидает готовности узлов
func (m *Manager) waitForNodes(ctx context.Context) error {
    cmd := exec.CommandContext(ctx, "kubectl", "wait", "--for=condition=Ready", "nodes", "--all", "--timeout=300s")
    cmd.Stdout = os.Stdout
    cmd.Stderr = os.Stderr
    return cmd.Run()
}