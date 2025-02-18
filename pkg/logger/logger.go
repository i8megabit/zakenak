package logger

import (
	"log"
	"os"
	"strings"
)

var (
	// Debug controls debug logging
	Debug bool
	logger *log.Logger
)

func init() {
	Debug = os.Getenv("ZAKENAK_DEBUG") == "true"
	logger = log.New(os.Stdout, "", log.LstdFlags)
}

// Info logs informational messages
func Info(format string, v ...interface{}) {
	logger.Printf("[INFO] "+format, v...)
}

// Error logs error messages
func Error(format string, v ...interface{}) {
	logger.Printf("[ERROR] "+format, v...)
}

// DebugLog logs debug messages when debug mode is enabled
func DebugLog(format string, v ...interface{}) {
	if Debug {
		logger.Printf("[DEBUG] "+format, v...)
	}
}

// Command logs command execution with its arguments
func Command(cmd string, args []string) {
	if Debug {
		logger.Printf("[DEBUG] Executing command: %s %s", cmd, strings.Join(args, " "))
	}
}

// CommandOutput logs command output in debug mode
func CommandOutput(output string) {
	if Debug && output != "" {
		logger.Printf("[DEBUG] Command output:\n%s", output)
	}
}

// CommandError logs command errors in debug mode
func CommandError(err error) {
	if Debug && err != nil {
		logger.Printf("[DEBUG] Command error: %v", err)
	}
}