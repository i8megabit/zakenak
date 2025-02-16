// Copyright (c) 2024 Mikhail Eberil
//
// This file is part of Zakenak project and is released under the terms of the
// MIT License. See LICENSE file in the project root for full license information.

package config

import (
    "github.com/docker/docker/api/types/events"
)

// Config представляет основную конфигурацию приложения
type Config struct {
    Docker   DockerConfig   `json:"docker"`
    Helm     HelmConfig     `json:"helm"`
    Runtime  RuntimeConfig  `json:"runtime"`
    Deploy   DeployConfig   `json:"deploy"`
}

// DockerConfig содержит настройки для Docker
type DockerConfig struct {
    Host      string       `json:"host"`
    TLS       bool        `json:"tls"`
    CertPath  string      `json:"certPath"`
    EventType events.Type `json:"eventType"`
}

// HelmConfig содержит настройки для Helm
type HelmConfig struct {
    KubeConfig string `json:"kubeConfig"`
    Namespace  string `json:"namespace"`
}

// RuntimeConfig содержит настройки времени выполнения
type RuntimeConfig struct {
    Debug     bool   `json:"debug"`
    LogLevel  string `json:"logLevel"`
    GPUEnable bool   `json:"gpuEnable"`
}

// DeployConfig содержит настройки развертывания
type DeployConfig struct {
    Namespace     string            `json:"namespace"`
    ChartPath     string           `json:"chartPath"`
    ReleaseName   string           `json:"releaseName"`
    Values        map[string]string `json:"values"`
    WaitTimeout   int              `json:"waitTimeout"`
    AutoRollback  bool             `json:"autoRollback"`
}
