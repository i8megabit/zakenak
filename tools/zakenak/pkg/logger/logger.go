package logger

import (
	"log"
	"os"
	"strings"
)

var (
	// Debug включает вывод отладочных сообщений
	Debug  bool
	logger *log.Logger
)

func init() {
	Debug = os.Getenv("ZAKENAK_DEBUG") == "true"
	logger = log.New(os.Stdout, "", log.LstdFlags)
}

// Info выводит информационные сообщения
func Info(format string, v ...interface{}) {
	logger.Printf("[INFO] "+format, v...)
}

// Error выводит сообщения об ошибках
func Error(format string, v ...interface{}) {
	logger.Printf("[ERROR] "+format, v...)
}

// DebugLog пишет отладочные сообщения, если режим включён
func DebugLog(format string, v ...interface{}) {
	if Debug {
		logger.Printf("[DEBUG] "+format, v...)
	}
}

// Command выводит команду и её аргументы
func Command(cmd string, args []string) {
	if Debug {
		logger.Printf("[DEBUG] Executing command: %s %s", cmd, strings.Join(args, " "))
	}
}

// CommandOutput пишет вывод команды в режиме отладки
func CommandOutput(output string) {
	if Debug && output != "" {
		logger.Printf("[DEBUG] Command output:\n%s", output)
	}
}

// CommandError пишет ошибку команды в режиме отладки
func CommandError(err error) {
	if Debug && err != nil {
		logger.Printf("[DEBUG] Command error: %v", err)
	}
}
