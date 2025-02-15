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
	Volumes     map[string]Volume     `json:"volumes"`
	GPU         GPUState              `json:"gpu"`
}

// Component представляет состояние компонента
type Component struct {
	Name        string    `json:"name"`
	Version     string    `json:"version"`
	Status      Status    `json:"status"`
	LastSync    time.Time `json:"lastSync"`
}

// Volume представляет информацию о томе
type Volume struct {
	Name        string    `json:"name"`
	Path        string    `json:"path"`
	Size        string    `json:"size"`
	LastUsed    time.Time `json:"lastUsed"`
	Components  []string  `json:"components"`
}

// GPUState представляет состояние GPU
type GPUState struct {
	Enabled     bool      `json:"enabled"`
	Driver      string    `json:"driver"`
	Memory      string    `json:"memory"`
	Devices     []Device  `json:"devices"`
}

// Device представляет GPU устройство
type Device struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Memory      string    `json:"memory"`
	InUse       bool      `json:"inUse"`
}

// Status представляет статус компонента
type Status string

const (
	StatusPending    Status = "Pending"
	StatusRunning    Status = "Running"
	StatusStopped    Status = "Stopped"
	StatusError      Status = "Error"
)
