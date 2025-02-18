package state

import (
	"sync"
)


// StateManager handles the state management for the application
type StateManager struct {
	mu    sync.RWMutex
	state map[string]interface{}
}

// NewStateManager creates a new instance of StateManager
func NewStateManager() *StateManager {
	return &StateManager{
		state: make(map[string]interface{}),
	}
}

// Get retrieves a value from the state
func (m *StateManager) Get(key string) (interface{}, bool) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	val, ok := m.state[key]
	return val, ok
}

// Set stores a value in the state
func (m *StateManager) Set(key string, value interface{}) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.state[key] = value
}

// Delete removes a value from the state
func (m *StateManager) Delete(key string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	delete(m.state, key)
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