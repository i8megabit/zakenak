/*
 * Copyright (c) 2024 Mikhail Eberil
 * 
 * This file is part of Ƶakenak™®, a GitOps deployment tool.
 * 
 * Ƶakenak™® is free software: you can redistribute it and/or modify
 * it under the terms of the MIT License with Trademark Protection.
 * 
 * Ƶakenak™® is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * MIT License for more details.
 * 
 * The name "Ƶakenak™®" and associated branding are trademarks of @eberil
 * and may not be used without express written permission.
 */

package deploy

import (
	"context"
	"fmt"
	"path/filepath"
	"github.com/i8meg/zakenak/pkg/config"
	"github.com/i8meg/zakenak/pkg/helm"
	"k8s.io/client-go/kubernetes"
)

// Manager управляет процессом развертывания
type Manager struct {
	client    *kubernetes.Clientset
	config    *config.Config
	helm      *helm.Client
	namespace string
}

// NewManager создает новый менеджер развертывания
func NewManager(client *kubernetes.Clientset, cfg *config.Config) *Manager {
	return &Manager{
		client:    client,
		config:    cfg,
		namespace: cfg.Deploy.Namespace,
	}
}

// Deploy выполняет развертывание всех компонентов
func (m *Manager) Deploy(ctx context.Context) error {
	// Создание namespace если не существует
	if err := m.ensureNamespace(ctx); err != nil {
		return fmt.Errorf("failed to ensure namespace: %w", err)
	}

	// Развертывание каждого чарта
	for _, chartPath := range m.config.Deploy.Charts {
		if err := m.deployChart(ctx, chartPath); err != nil {
			return fmt.Errorf("failed to deploy chart %s: %w", chartPath, err)
		}
	}

	return nil
}

// ensureNamespace создает namespace если он не существует
func (m *Manager) ensureNamespace(ctx context.Context) error {
	// Имплементация создания namespace
	return nil
}

// deployChart разворачивает отдельный Helm чарт
func (m *Manager) deployChart(ctx context.Context, chartPath string) error {
	// Получение абсолютного пути к чарту
	absPath, err := filepath.Abs(chartPath)
	if err != nil {
		return fmt.Errorf("failed to get absolute path: %w", err)
	}

	// Проверка существования чарта
	if err := m.helm.ValidateChart(absPath); err != nil {
		return fmt.Errorf("chart validation failed: %w", err)
	}

	// Установка/обновление чарта
	if err := m.helm.UpgradeOrInstall(ctx, absPath, m.namespace); err != nil {
		return fmt.Errorf("chart deployment failed: %w", err)
	}

	return nil
}