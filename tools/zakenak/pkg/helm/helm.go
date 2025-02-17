/*
 * Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
 * 
 * This file is part of Ƶakenak™® project.
 * https://github.com/i8megabit/zakenak
 *
 * This program is free software and is released under the terms of the MIT License.
 * See LICENSE.md file in the project root for full license information.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 *
 * TRADEMARK NOTICE:
 * Ƶakenak™® and the Ƶakenak logo are registered trademarks of Mikhail Eberil.
 * All rights reserved. The Ƶakenak trademark and brand may not be used in any way 
 * without express written permission from the trademark owner.
 */

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