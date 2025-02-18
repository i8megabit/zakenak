package cluster

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"github.com/i8megabit/zakenak/pkg/system"
)

// ClusterManager handles Kubernetes cluster operations
type ClusterManager struct {
	detector *system.SystemDetector
	baseDir  string
}

// NewClusterManager creates a new instance of ClusterManager
func NewClusterManager(baseDir string) (*ClusterManager, error) {
	if baseDir == "" {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return nil, fmt.Errorf("failed to get home directory: %w", err)
		}
		baseDir = filepath.Join(homeDir, ".zakenak")
	}

	return &ClusterManager{
		detector: &system.SystemDetector{},
		baseDir:  baseDir,
	}, nil
}

// CreateCluster creates a new Kubernetes cluster
func (m *ClusterManager) CreateCluster(ctx context.Context, name string) error {
	// Проверяем наличие необходимых инструментов
	if err := m.checkDependencies(ctx); err != nil {
		return fmt.Errorf("dependency check failed: %w", err)
	}

	// Создаем директорию для кластера
	clusterDir := filepath.Join(m.baseDir, "clusters", name)
	if err := os.MkdirAll(clusterDir, 0755); err != nil {
		return fmt.Errorf("failed to create cluster directory: %w", err)
	}

	// Запускаем создание кластера с таймаутом
	ctx, cancel := context.WithTimeout(ctx, 5*time.Minute)
	defer cancel()

	cmd := exec.CommandContext(ctx, "kind", "create", "cluster", "--name", name)
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("failed to create cluster: %w, output: %s", err, output)
	}

	return nil
}

// checkDependencies проверяет наличие необходимых инструментов
func (m *ClusterManager) checkDependencies(ctx context.Context) error {
	cmd := exec.CommandContext(ctx, "kind", "version")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("kind is not installed or not accessible: %w", err)
	}
	return nil
}

/* 
MIT License

Copyright (c) 2024 @eberil

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
*/