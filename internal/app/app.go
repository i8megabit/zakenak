package app

import (
	"github.com/i8meg/zakenak/internal/config"
)

// App represents the main application
type App struct {
	config *config.Config
}

// New creates a new App instance
func New(cfg *config.Config) *App {
	return &App{
		config: cfg,
	}
}

// Run starts the application
func (a *App) Run() error {
	// TODO: Implement application logic
	return nil
}