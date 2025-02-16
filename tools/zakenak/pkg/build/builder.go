// Copyright (c) 2024 Mikhail Eberil
//
// This file is part of Zakenak project and is released under the terms of the
// MIT License. See LICENSE file in the project root for full license information.

package build

import (
    "github.com/i8megabit/zakenak/pkg/config"
)

// Builder управляет процессом сборки
type Builder struct {
    config *config.BuildConfig
}

// NewBuilder создает новый экземпляр Builder
func NewBuilder(cfg *config.BuildConfig) *Builder {
    return &Builder{
        config: cfg,
    }
}

// Configure настраивает параметры сборки
func (b *Builder) Configure() error {
    capabilities := "compute,utility"
    requirements := "cuda>=12.8"
    
    b.config.Capabilities = &capabilities
    b.config.Requirements = &requirements
    
    return nil
}
