package state

import (
	"time"
	"encoding/json"
)

// State представляет текущее состояние системы
type State struct {
	Version     string                 `json:"version"`
	LastUpdate  time.Time             `json:"lastUpdate"`
	Components  map[string]Component  `json:"components"`
	Resources   Resources             `json:"resources"`
	Status      Status                `json:"status"`
}

// Component представляет состояние отдельного компонента
type Component struct {
	Name        string            `json:"name"`
	Version     string            `json:"version"`
	Status      ComponentStatus   `json:"status"`
	LastSync    time.Time         `json:"lastSync"`
	Config      json.RawMessage   `json:"config,omitempty"`
	Dependencies []string         `json:"dependencies,omitempty"`
}

// Resources представляет состояние ресурсов
type Resources struct {
	Images      []Image     `json:"images"`
	Charts      []Chart     `json:"charts"`
	Configs     []Config    `json:"configs"`
}

// Image представляет Docker образ
type Image struct {
	Name        string    `json:"name"`
	Tag         string    `json:"tag"`
	Digest      string    `json:"digest"`
	BuildTime   time.Time `json:"buildTime"`
	UseGPU      bool      `json:"useGPU,omitempty"`
}

// Chart представляет Helm чарт
type Chart struct {
	Name        string    `json:"name"`
	Version     string    `json:"version"`
	Values      string    `json:"values,omitempty"`
	LastApplied time.Time `json:"lastApplied"`
}

// Config представляет конфигурацию
type Config struct {
	Name     string          `json:"name"`
	Type     string          `json:"type"`
	Data     json.RawMessage `json:"data"`
}

// Status представляет общий статус системы
type Status struct {
	Phase          StatusPhase `json:"phase"`
	Message        string      `json:"message,omitempty"`
	LastTransition time.Time   `json:"lastTransition"`
}

// ComponentStatus представляет статус компонента
type ComponentStatus string

const (
	StatusPending    ComponentStatus = "Pending"
	StatusConverging ComponentStatus = "Converging"
	StatusReady      ComponentStatus = "Ready"
	StatusFailed     ComponentStatus = "Failed"
)

// StatusPhase представляет фазу состояния
type StatusPhase string

const (
	PhaseInitializing StatusPhase = "Initializing"
	PhaseConverging   StatusPhase = "Converging"
	PhaseReady        StatusPhase = "Ready"
	PhaseFailed       StatusPhase = "Failed"
)

// StateManager управляет состоянием
type StateManager interface {
	// Load загружает состояние
	Load() (*State, error)
	
	// Save сохраняет состояние
	Save(*State) error
	
	// Update обновляет состояние
	Update(func(*State) error) error
}