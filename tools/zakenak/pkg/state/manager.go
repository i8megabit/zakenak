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


package state

import (
    "encoding/json"
    "fmt"
    "os"
    "path/filepath"
    "sync"
    "time"
)

// FileStateManager реализует StateManager используя файловую систему
type FileStateManager struct {
    path string
    mu   sync.RWMutex
}

// NewFileStateManager создает новый FileStateManager
func NewFileStateManager(path string) *FileStateManager {
    return &FileStateManager{
        path: path,
    }
}

// Load загружает состояние из файла
func (m *FileStateManager) Load() (*State, error) {
    m.mu.RLock()
    defer m.mu.RUnlock()

    data, err := os.ReadFile(m.path)
    if err != nil {
        if os.IsNotExist(err) {
            // Возвращаем новое состояние если файл не существует
            return &State{
                Version:    "1.0.0",
                LastUpdate: time.Now(),
                Components: make(map[string]Component),
                Status: Status{
                    Phase:          PhaseInitializing,
                    LastTransition: time.Now(),
                },
            }, nil
        }
        return nil, fmt.Errorf("failed to read state file: %w", err)
    }

    var state State
    if err := json.Unmarshal(data, &state); err != nil {
        return nil, fmt.Errorf("failed to unmarshal state: %w", err)
    }

    return &state, nil
}

// Save сохраняет состояние в файл
func (m *FileStateManager) Save(state *State) error {
    m.mu.Lock()
    defer m.mu.Unlock()

    // Обновляем время последнего обновления
    state.LastUpdate = time.Now()

    // Создаем директорию если не существует
    if err := os.MkdirAll(filepath.Dir(m.path), 0755); err != nil {
        return fmt.Errorf("failed to create state directory: %w", err)
    }

    // Маршалим состояние
    data, err := json.MarshalIndent(state, "", "  ")
    if err != nil {
        return fmt.Errorf("failed to marshal state: %w", err)
    }

    // Записываем во временный файл
    tmpPath := m.path + ".tmp"
    if err := os.WriteFile(tmpPath, data, 0644); err != nil {
        return fmt.Errorf("failed to write state file: %w", err)
    }

    // Атомарно переименовываем
    if err := os.Rename(tmpPath, m.path); err != nil {
        os.Remove(tmpPath) // Очищаем временный файл в случае ошибки
        return fmt.Errorf("failed to rename state file: %w", err)
    }

    return nil
}

// Update обновляет состояние атомарно
func (m *FileStateManager) Update(fn func(*State) error) error {
    m.mu.Lock()
    defer m.mu.Unlock()

    // Загружаем текущее состояние
    state, err := m.Load()
    if err != nil {
        return err
    }

    // Применяем обновление
    if err := fn(state); err != nil {
        return err
    }

    // Сохраняем обновленное состояние
    return m.Save(state)
}