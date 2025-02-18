// Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
//
// This file is part of Zakenak project and is released under the terms of the
// MIT License. See LICENSE file in the project root for full license information.

package git

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
	"github.com/i8megabit/zakenak/pkg/logger"
)

// logDebug выводит отладочную информацию
func (m *Manager) logDebug(format string, args ...interface{}) {
	if m.debug {
		log.Printf("[GIT DEBUG] "+format, args...)
	}
}

// Manager предоставляет интерфейс для работы с Git
type Manager struct {
	workDir        string
	originalBranch string
	debug         bool
}

// NewManager создает новый экземпляр Manager
func NewManager(workDir string) *Manager {
	return &Manager{
		workDir: workDir,
		debug:  os.Getenv("ZAKENAK_DEBUG") == "true",
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

// RestoreOriginalBranch восстанавливает исходную ветку и удаляет main
func (m *Manager) RestoreOriginalBranch() error {
	if m.originalBranch == "" || m.originalBranch == "main" {
		return nil
	}

	// Проверяем существование оригинальной ветки
	if err := m.run("rev-parse", "--verify", m.originalBranch); err == nil {
		// Переключаемся на оригинальную ветку
		if err := m.run("checkout", m.originalBranch); err != nil {
			return fmt.Errorf("failed to restore original branch %s: %w", m.originalBranch, err)
		}

		// Удаляем ветку main если она существует и мы не на ней
		if err := m.run("rev-parse", "--verify", "main"); err == nil {
			if err := m.run("branch", "-D", "main"); err != nil {
				return fmt.Errorf("failed to delete main branch: %w", err)
			}
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
		"safe.directory":     m.workDir, // Changed from "*" to specific directory
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
	if m.debug {
		m.logDebug("Starting EnsureMainBranch operation")
		m.logDebug("Working directory: %s", m.workDir)
	}

	// Сначала настраиваем глобальные параметры Git
	if err := m.ConfigureGlobal(); err != nil {
		m.logDebug("Failed to configure global git settings: %v", err)
		return fmt.Errorf("failed to configure git: %w", err)
	}

	// Сохраняем текущую ветку перед переключением
	if err := m.SaveCurrentBranch(); err != nil {
		m.logDebug("Failed to save current branch: %v", err)
		return err
	}

	// Проверяем существование .git директории
	if _, err := os.Stat(m.workDir + "/.git"); os.IsNotExist(err) {
		m.logDebug("Git repository not found, initializing new one")
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
		m.logDebug("Main branch not found, checking current branch")
		currentBranch, err := m.getCurrentBranch()
		if err != nil {
			m.logDebug("Failed to get current branch: %v", err)
			return fmt.Errorf("failed to get current branch: %w", err)
		}
		m.logDebug("Current branch: %s", currentBranch)
		
		if currentBranch != "main" {
			m.logDebug("Creating main branch")
			if err := m.run("checkout", "-B", "main"); err != nil {
				return fmt.Errorf("failed to create main branch: %w", err)
			}
		}
	} else {
		m.logDebug("Checking out existing main branch")
		if err := m.run("checkout", "main", "--no-track"); err != nil {
			return fmt.Errorf("failed to checkout main: %w", err)
		}
	}

	m.logDebug("Unsetting upstream for main branch")
	m.run("branch", "--unset-upstream")

	m.logDebug("EnsureMainBranch completed successfully")
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

// run выполняет git команду с расширенным логированием
func (m *Manager) run(args ...string) error {
	logger.Command("git", args)
	
	cmd := exec.Command("git", args...)
	cmd.Dir = m.workDir
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if m.debug {
		m.logDebug("Executing git command: git %s", strings.Join(args, " "))
		m.logDebug("Working directory: %s", m.workDir)
	}

	err := cmd.Run()
	if err != nil {
		logger.CommandError(err)
		if m.debug {
			m.logDebug("Git command failed: %v", err)
			// Проверяем состояние репозитория
			m.logDebug("Checking repository state...")
			if _, err := os.Stat(m.workDir + "/.git"); os.IsNotExist(err) {
				m.logDebug("Git repository does not exist at %s", m.workDir)
			} else {
				if head, err := m.output("rev-parse", "--abbrev-ref", "HEAD"); err == nil {
					m.logDebug("Current branch: %s", head)
				}
				if status, err := m.output("status", "--porcelain"); err == nil {
					m.logDebug("Working directory status:\n%s", status)
				}
			}
		}
		return fmt.Errorf("git command failed: %w", err)
	}
	return nil
}

// output выполняет git команду и возвращает вывод с логированием
func (m *Manager) output(args ...string) (string, error) {
	logger.Command("git", args)
	
	if m.debug {
		m.logDebug("Executing git command for output: git %s", strings.Join(args, " "))
	}

	cmd := exec.Command("git", args...)
	cmd.Dir = m.workDir
	out, err := cmd.Output()
	
	if err != nil {
		logger.CommandError(err)
		if m.debug {
			m.logDebug("Git command failed: %v", err)
			if exitErr, ok := err.(*exec.ExitError); ok {
				m.logDebug("Stderr: %s", string(exitErr.Stderr))
			}
		}
		return "", err
	}
	
	output := string(out)
	logger.CommandOutput(output)
	if m.debug {
		m.logDebug("Command output: %s", output)
	}
	return output, nil
}