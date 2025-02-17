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
