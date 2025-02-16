/*
 * Copyright (c) 2024 Mikhail Eberil
 *
 * This file is part of Zakenak project and is released under the terms of the
 * MIT License. See LICENSE file in the project root for full license information.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 *
 * The name "Zakenak" and associated branding are trademarks of @eberil
 * and may not be used without express written permission.
 */

package gpu

import (
	"fmt"
	"os/exec"
	"strings"
)

const (
	minDriverVersion = "535.104.05"
	minCUDAVersion   = "12.8"
)

// CheckRequirements проверяет соответствие системы GPU требованиям
func CheckRequirements() error {
	// Проверка наличия nvidia-smi
	if err := checkNVIDIASMI(); err != nil {
		return fmt.Errorf("nvidia-smi check failed: %w", err)
	}

	// Проверка версии драйвера
	if err := checkDriverVersion(); err != nil {
		return fmt.Errorf("driver version check failed: %w", err)
	}

	// Проверка CUDA
	if err := checkCUDA(); err != nil {
		return fmt.Errorf("CUDA check failed: %w", err)
	}

	return nil
}

// checkNVIDIASMI проверяет наличие и работоспособность nvidia-smi
func checkNVIDIASMI() error {
	cmd := exec.Command("nvidia-smi")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("nvidia-smi not found or failed: %w", err)
	}
	return nil
}

// checkDriverVersion проверяет версию драйвера NVIDIA
func checkDriverVersion() error {
	cmd := exec.Command("nvidia-smi", "--query-gpu=driver_version", "--format=csv,noheader")
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("failed to get driver version: %w", err)
	}

	version := strings.TrimSpace(string(output))
	if !isVersionSufficient(version, minDriverVersion) {
		return fmt.Errorf("driver version %s is below minimum required %s", version, minDriverVersion)
	}

	return nil
}

// checkCUDA проверяет наличие и версию CUDA
func checkCUDA() error {
	cmd := exec.Command("nvcc", "--version")
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("CUDA toolkit not found: %w", err)
	}

	version := extractCUDAVersion(string(output))
	if !isVersionSufficient(version, minCUDAVersion) {
		return fmt.Errorf("CUDA version %s is below minimum required %s", version, minCUDAVersion)
	}

	return nil
}

// isVersionSufficient сравнивает версии
func isVersionSufficient(current, minimum string) bool {
	// Простое сравнение строк (можно улучшить для более сложных номеров версий)
	return current >= minimum
}

// extractCUDAVersion извлекает версию CUDA из вывода nvcc --version
func extractCUDAVersion(output string) string {
	// Пример строки: "Cuda compilation tools, release 12.8, V12.8.123"
	parts := strings.Split(output, "release ")
	if len(parts) < 2 {
		return ""
	}
	version := strings.Split(parts[1], ",")[0]
	return strings.TrimSpace(version)
}