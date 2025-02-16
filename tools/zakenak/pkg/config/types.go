// Copyright (c) 2024 Mikhail Eberil
//
// This file is part of Zakenak project and is released under the terms of the
// MIT License. See LICENSE file in the project root for full license information.

package config

// Config представляет основную конфигурацию приложения

type Config struct {
    Docker   DockerConfig   `json:"docker"`
    Helm     HelmConfig     `json:"helm"`
    Runtime  RuntimeConfig  `json:"runtime"`
    Build    BuildConfig    `json:"build"`
    Deploy   DeployConfig   `json:"deploy"`
    Git      GitConfig      `json:"git"`
    Registry RegistryConfig `json:"registry"`
    Project  string         `json:"project"`
}

// BuildConfig содержит настройки для сборки
type BuildConfig struct {
    Capabilities *string          `json:"capabilities"` // CUDA capabilities
    Requirements *string          `json:"requirements"` // CUDA requirements
    BaseImage    string           `json:"baseImage"`
    BuildArgs    map[string]string `json:"buildArgs"`
    GPU          GPUConfig        `json:"gpu"`
    Dockerfile   string           `json:"dockerfile"`
    Context      string           `json:"context"`
    Args         map[string]string `json:"args"`
}

// GPUConfig содержит настройки GPU
type GPUConfig struct {
    Enabled  bool   `json:"enabled"`
    Memory   string `json:"memory"`
    Devices  string `json:"devices"`
}

// GitConfig содержит настройки Git
type GitConfig struct {
    Branch   string   `json:"branch"`
    Paths    []string `json:"paths"`
    Strategy string   `json:"strategy"`
}

// RegistryConfig содержит настройки registry
type RegistryConfig struct {
    URL      string `json:"url"`
    Username string `json:"username"`
    Password string `json:"password"`
}

// DockerConfig содержит настройки для Docker
type DockerConfig struct {
    Host      string       `json:"host"`
    TLS       bool        `json:"tls"`
    CertPath  string      `json:"certPath"`
    EventType string      `json:"eventType"` // Changed from events.Type to string
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
    Charts        []string         `json:"charts"`
}
