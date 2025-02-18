package state

import (
    "encoding/json"
    "fmt"
    "os"
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
    return m.loadWithoutLock()
}

// loadWithoutLock загружает состояние без блокировки
func (m *FileStateManager) loadWithoutLock() (*State, error) {
    if _, err := os.Stat(m.path); os.IsNotExist(err) {
        return &State{
            Version:    "1.0.0",
            LastUpdate: time.Now(),
            Components: make(map[string]Component),
            Status: Status{
                Phase:          PhaseInitializing,
                LastTransition: time.Now(),
            },
            GPU: GPUState{
                Enabled: true,
                Driver:  "auto",
            },
        }, nil
    }

    data, err := os.ReadFile(m.path)
    if err != nil {
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
    return m.saveWithoutLock(state)
}

// saveWithoutLock сохраняет состояние без блокировки
func (m *FileStateManager) saveWithoutLock(state *State) error {
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
    // Create state directory if it doesn't exist
    if err := os.MkdirAll(filepath.Dir(m.path), 0755); err != nil {
        return fmt.Errorf("failed to create state directory: %w", err)
    }

    // First load state without lock
    state, err := m.loadWithoutLock()
    if err != nil {
        return err
    }

    // Apply update
    if err := fn(state); err != nil {
        return err
    }

    // Now acquire write lock only for save
    m.mu.Lock()
    defer m.mu.Unlock()
    
    return m.saveWithoutLock(state)
}