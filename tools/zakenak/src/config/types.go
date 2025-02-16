// Copyright (c)  2025 Mikhail Eberil
//
// This file is part of Zakenak project and is released under the terms of the
// MIT License. See LICENSE file in the project root for full license information.

package config

// Config представляет основную конфигурацию приложения
type Config struct {
	Project     string       `yaml:"project"`
	Environment string       `yaml:"environment"`
	Registry    Registry     `yaml:"registry"`
	Deploy      Deploy       `yaml:"deploy"`
	Build       Build        `yaml:"build"`
	Git         Git          `yaml:"git"`
}

// Registry содержит настройки container registry
type Registry struct {
	URL      string `yaml:"url"`
	Username string `yaml:"username"`
	Password string `yaml:"password"`
}

// Deploy содержит настройки развертывания
type Deploy struct {
	Namespace   string   `yaml:"namespace"`
	Charts      []string `yaml:"charts"`
	Values      []string `yaml:"values"`
}

// Build содержит настройки сборки
type Build struct {
	Context    string            `yaml:"context"`
	Dockerfile string            `yaml:"dockerfile"`
	Args       map[string]string `yaml:"args"`
	GPU        GPU               `yaml:"gpu"`
}

// GPU содержит настройки GPU
type GPU struct {
	Enabled  bool   `yaml:"enabled"`
	Runtime  string `yaml:"runtime"`
	Memory   string `yaml:"memory"`
	Devices  string `yaml:"devices"`
}

// Git содержит настройки Git
type Git struct {
	Branch   string   `yaml:"branch"`
	Paths    []string `yaml:"paths"`
	Strategy string   `yaml:"strategy"`
}