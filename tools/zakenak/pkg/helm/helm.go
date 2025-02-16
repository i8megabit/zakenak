// Copyright (c) 2024 Mikhail Eberil
//
// This file is part of Zakenak project and is released under the terms of the
// MIT License. See LICENSE file in the project root for full license information.

package helm

import (
	"fmt"
	"os/exec"
)

// Client represents the base structure for working with Helm
type Client struct {
	// Client configuration
}

// NewClient creates a new instance of Helm client
func NewClient() *Client {
	return &Client{}
}

// ValidateChart validates a Helm chart at the given path
func (c *Client) ValidateChart(chartPath string) error {
	cmd := exec.Command("helm", "lint", chartPath)
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("chart validation failed: %s: %w", string(output), err)
	}
	return nil
}