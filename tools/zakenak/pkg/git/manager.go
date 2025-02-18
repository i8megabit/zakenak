// Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
//
// This file is part of Zakenak project and is released under the terms of the
// MIT License. See LICENSE file in the project root for full license information.

package git

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// Manager предоставляет интерфейс для работы с Git
type Manager struct {
	workDir       string
	originalBranch string
}

// NewManager создает новый экземпляр Manager
func NewManager(workDir string) *Manager {
	return &Manager{
		workDir: workDir,
	}
}

// SaveCurrentBranch сохраняет текущую ветку
func (m *Manager) SaveCurrentBranch() error {
	branch, err := m.getCurrentBranch()
	if err != nil {
		return fmt.Errorf("failed to get current branch: %w", err)
	}
	m.originalBranch = branch
	return nil
}

// RestoreOriginalBranch восстанавливает исходную ветку
func (m *Manager) RestoreOriginalBranch() error {
	if m.originalBranch == "" || m.originalBranch == "main" {
		return nil
	}

	// Проверяем существование ветки
	if err := m.run("rev-parse", "--verify", m.originalBranch); err == nil {
		if err := m.run("checkout", m.originalBranch); err != nil {
			return fmt.Errorf("failed to restore original branch %s: %w", m.originalBranch, err)
		}
	}
	return nil
}

// InitRepo инициализирует Git репозиторий
func (m *Manager) InitRepo() error {
	if err := m.run("init"); err != nil {
		return fmt.Errorf("failed to init repository: %w", err)
	}
	return nil
}

// ConfigureGlobal устанавливает глобальные настройки Git
func (m *Manager) ConfigureGlobal() error {
	configs := map[string]string{
		"safe.directory":     "*",
		"init.defaultBranch": "main",
		"user.email":         "zakenak@local",
		"user.name":         "Zakenak",
	}

	for key, value := range configs {
		if err := m.run("config", "--global", key, value); err != nil {
			return fmt.Errorf("failed to set global config %s: %w", key, err)
		}
	}
	return nil
}

// EnsureMainBranch проверяет и создает ветку main если необходимо
func (m *Manager) EnsureMainBranch() error {
	// Сохраняем текущую ветку перед переключением
	if err := m.SaveCurrentBranch(); err != nil {
		return err
	}

	// Проверяем существование .git директории
	if _, err := os.Stat(m.workDir + "/.git"); os.IsNotExist(err) {
		if err := m.InitRepo(); err != nil {
			return err
		}
		if err := m.run("add", "."); err != nil {
			return fmt.Errorf("failed to add files: %w", err)
		}
		if err := m.run("commit", "-m", "Initial commit by Zakenak"); err != nil {
			return fmt.Errorf("failed to create initial commit: %w", err)
		}
		if err := m.run("branch", "-M", "main"); err != nil {
			return fmt.Errorf("failed to create main branch: %w", err)
		}
		return nil
	}

	// Проверяем существование ветки main
	if err := m.run("rev-parse", "--verify", "main"); err != nil {
		currentBranch, err := m.getCurrentBranch()
		if err != nil {
			return fmt.Errorf("failed to get current branch: %w", err)
		}
		if currentBranch != "main" {
			// Создаем main ветку из текущей
			if err := m.run("checkout", "-B", "main"); err != nil {
				return fmt.Errorf("failed to create main branch: %w", err)
			}
		}
	} else {
		// Переключаемся на существующую main ветку
		if err := m.run("checkout", "main", "--no-track"); err != nil {
			return fmt.Errorf("failed to checkout main: %w", err)
		}
	}

	// Отключаем отслеживание upstream для main ветки
	m.run("branch", "--unset-upstream")

	return nil
}

// getCurrentBranch возвращает текущую ветку
func (m *Manager) getCurrentBranch() (string, error) {
	out, err := m.output("rev-parse", "--abbrev-ref", "HEAD")
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(out), nil
}

// run выполняет git команду
func (m *Manager) run(args ...string) error {
	cmd := exec.Command("git", args...)
	cmd.Dir = m.workDir
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// output выполняет git команду и возвращает вывод
func (m *Manager) output(args ...string) (string, error) {
	cmd := exec.Command("git", args...)
	cmd.Dir = m.workDir
	out, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return string(out), nil
}