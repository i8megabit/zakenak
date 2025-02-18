package main

import (
	"fmt"
)

func handleClusterCommand(args []string) error {
	if len(args) < 1 {
		return fmt.Errorf("cluster command requires subcommand")
	}

	switch args[0] {
	case "create":
		return createCluster(args[1:])
	default:
		return fmt.Errorf("unknown cluster subcommand: %s", args[0])
	}
}

func createCluster(args []string) error {
	// Базовая заглушка для создания кластера
	fmt.Println("Creating cluster...")
	return nil
}

/* 
MIT License

Copyright (c) 2024 @eberil

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
*/