// (c) 2023-2025 Mikhail Eberil (@eberil)
//
// Этот файл — часть проекта Zakenak и распространяется по лицензии MIT.
// Подробности смотрите в файле LICENSE в корне репозитория.

package helm

import (
	"fmt"
	"os/exec"
)

// Client описывает базовый клиент Helm
type Client struct {
	// Параметры клиента
}

// NewClient возвращает новый экземпляр клиента Helm
func NewClient() *Client {
	return &Client{}
}

// ValidateChart проверяет Helm чарт по указанному пути
func (c *Client) ValidateChart(chartPath string) error {
	cmd := exec.Command("helm", "lint", chartPath)
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("chart validation failed: %s: %w", string(output), err)
	}
	return nil
}
