package main

import (
	"fmt"
	"os"
)

var Version = "development"

func main() {
	if len(os.Args) > 1 && os.Args[1] == "--version" {
		fmt.Printf("Zakenak version: %s\n", Version)
		return
	}

	if len(os.Args) > 1 && os.Args[1] == "--help" {
		fmt.Println("Usage: zakenak [command] [options]")
		fmt.Println("\nCommands:")
		fmt.Println("  cluster     Manage Kubernetes cluster")
		fmt.Println("\nOptions:")
		fmt.Println("  --version   Show version")
		fmt.Println("  --help      Show help")
		fmt.Println("  --config    Specify config file")
		return
	}
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