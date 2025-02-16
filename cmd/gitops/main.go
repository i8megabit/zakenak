/*
 * Copyright (c) 2024 Mikhail Eberil
 * 
 * This file is part of Zakenak, a GitOps deployment tool.
 * 
 * Zakenak is free software: you can redistribute it and/or modify
 * it under the terms of the MIT License with Trademark Protection.
 * 
 * Zakenak is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * MIT License for more details.
 * 
 * The name "Zakenak" and associated branding are trademarks of @eberil
 * and may not be used without express written permission.
 */

package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
)

var (
	Version   = "dev"
	Commit    = "none"
	BuildDate = "unknown"
)

func main() {
	log.Printf("Ƶakenak™® Version: %s (Commit: %s, Built: %s)\n", Version, Commit, BuildDate)

	if err := run(); err != nil {
		log.Fatalf("Error: %v", err)
	}
}

func run() error {
	// Базовая конфигурация логирования
	log.SetFlags(log.Ldate | log.Ltime | log.LUTC)
	
	// Получение рабочей директории
	workDir, err := os.Getwd()
	if err != nil {
		return fmt.Errorf("unable to get working directory: %w", err)
	}

	// Поиск конфигурационного файла
	configPath := filepath.Join(workDir, "zakenak.yaml")
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		return fmt.Errorf("configuration file not found at %s", configPath)
	}

	log.Printf("Starting Ƶakenak™® in %s", workDir)
	return nil
}