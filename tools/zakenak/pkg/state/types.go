// Package state предоставляет типы и функции для управления состоянием системы
package state

import (
    "time"
    "encoding/json"
)

// State представляет текущее состояние системы, включая информацию о компонентах,
// томах и GPU устройствах. Используется для отслеживания и сохранения состояния
// между перезапусками.
type State struct {
    Version     string                 `json:"version"`     // Версия формата состояния
    LastUpdate  time.Time             `json:"lastUpdate"`  // Время последнего обновления
    Components  map[string]Component  `json:"components"`  // Карта компонентов системы
    Volumes     map[string]Volume     `json:"volumes"`     // Карта томов
    GPU         GPUState              `json:"gpu"`         // Состояние GPU
}

// Component представляет состояние отдельного компонента системы,
// включая его версию, статус и время последней синхронизации.
type Component struct {
    Name        string    `json:"name"`       // Имя компонента
    Version     string    `json:"version"`    // Версия компонента
    Status      Status    `json:"status"`     // Текущий статус
    LastSync    time.Time `json:"lastSync"`   // Время последней синхронизации
}

// Volume представляет информацию о томе в системе,
// включая его размер и связанные компоненты.
type Volume struct {
    Name        string    `json:"name"`       // Имя тома
    Path        string    `json:"path"`       // Путь монтирования
    Size        string    `json:"size"`       // Размер тома
    LastUsed    time.Time `json:"lastUsed"`   // Время последнего использования
    Components  []string  `json:"components"` // Список компонентов, использующих том
}

// GPUState представляет состояние GPU в системе,
// включая информацию о драйвере и устройствах.
type GPUState struct {
    Enabled     bool      `json:"enabled"`    // Флаг включения GPU
    Driver      string    `json:"driver"`     // Версия драйвера
    Memory      string    `json:"memory"`     // Доступная память
    Devices     []Device  `json:"devices"`    // Список GPU устройств
}

// Device представляет отдельное GPU устройство в системе.
type Device struct {
    ID          string    `json:"id"`         // Идентификатор устройства
    Name        string    `json:"name"`       // Название устройства
    Memory      string    `json:"memory"`     // Память устройства
    InUse       bool      `json:"inUse"`      // Флаг использования
}

// Status представляет возможные состояния компонента
type Status string

// Константы для различных статусов компонента
const (
    StatusPending    Status = "Pending"    // Компонент ожидает инициализации
    StatusRunning    Status = "Running"    // Компонент работает
    StatusStopped    Status = "Stopped"    // Компонент остановлен
    StatusError      Status = "Error"      // Ошибка в работе компонента
)
