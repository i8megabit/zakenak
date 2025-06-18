package main

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
)

// ensureWorkspaceGit initializes a git repo in WORKSPACE_DIR.
func ensureWorkspaceGit(t *testing.T) string {
	work := os.Getenv("WORKSPACE_DIR")
	if work == "" {
		work = t.TempDir()
		os.Setenv("WORKSPACE_DIR", work)
	}
	if _, err := os.Stat(filepath.Join(work, ".git")); os.IsNotExist(err) {
		if err := exec.Command("git", "init", work).Run(); err != nil {
			t.Fatalf("git init: %v", err)
		}
		exec.Command("git", "config", "--global", "user.email", "test@example.com").Run()
		exec.Command("git", "config", "--global", "user.name", "test").Run()
		if err := exec.Command("git", "-C", work, "checkout", "-b", "main").Run(); err != nil {
			t.Fatalf("git checkout: %v", err)
		}
		exec.Command("git", "-C", work, "commit", "--allow-empty", "-m", "init").Run()
	} else {
		if err := exec.Command("git", "-C", work, "rev-parse", "HEAD").Run(); err != nil {
			exec.Command("git", "-C", work, "commit", "--allow-empty", "-m", "init").Run()
		}
	}
	return work
}

// createFakeCommands creates stub executables used by the CLI.
func createFakeCommands(t *testing.T) (string, func()) {
	dir := t.TempDir()
	cmds := map[string]string{
		"nvidia-smi": "#!/bin/sh\nif [ \"$1\" = \"--query-gpu=driver_version\" ]; then echo 535.0; fi\n",
		"docker":     "#!/bin/sh\nexit 0\n",
		"helm":       "#!/bin/sh\nexit 0\n",
		"kubectl":    "#!/bin/sh\nexit 0\n",
		"kind":       "#!/bin/sh\nexit 0\n",
		"nvidia-ctk": "#!/bin/sh\nexit 0\n",
	}
	for name, content := range cmds {
		path := filepath.Join(dir, name)
		if err := os.WriteFile(path, []byte(content), 0755); err != nil {
			t.Fatalf("write stub %s: %v", name, err)
		}
	}

	oldPath := os.Getenv("PATH")
	os.Setenv("PATH", dir+":"+oldPath)
	return dir, func() { os.Setenv("PATH", oldPath) }
}

// createConfig writes a minimal config and kubeconfig for tests.
func createConfig(t *testing.T, dir string) {
	cfg := `project: demo
deploy:
  namespace: prod
  charts: [./chart]
build:
  context: .
  dockerfile: Dockerfile
  gpu:
    enabled: true
  args:
    VERSION: v1
registry:
  url: example.com
git:
  branch: main
`
	if err := os.WriteFile(filepath.Join(dir, "config.yaml"), []byte(cfg), 0644); err != nil {
		t.Fatalf("write config: %v", err)
	}
	configPath = filepath.Join(dir, "config.yaml")

	kube := `apiVersion: v1
clusters:
- cluster:
    server: https://example.com
  name: test
contexts:
- context:
    cluster: test
    user: test
  name: test
current-context: test
kind: Config
preferences: {}
users:
- name: test
  user:
    token: dummytoken
`
	if err := os.WriteFile(filepath.Join(dir, "kubeconfig"), []byte(kube), 0644); err != nil {
		t.Fatalf("write kubeconfig: %v", err)
	}
	kubeconfig = filepath.Join(dir, "kubeconfig")
}

func TestRunConverge(t *testing.T) {
	work := ensureWorkspaceGit(t)
	dir, cleanup := createFakeCommands(t)
	defer cleanup()
	os.Setenv("HOME", dir)
	createConfig(t, dir)
	cwd, _ := os.Getwd()
	os.Chdir(work)
	defer os.Chdir(cwd)

	if err := runConverge(); err != nil {
		t.Fatalf("runConverge failed: %v", err)
	}
}

func TestRunBuild(t *testing.T) {
	dir := t.TempDir()
	createConfig(t, dir)
	if err := runBuild(); err != nil {
		t.Fatalf("runBuild failed: %v", err)
	}
}

func TestRunDeploy(t *testing.T) {
	work := ensureWorkspaceGit(t)
	dir, cleanup := createFakeCommands(t)
	defer cleanup()
	os.Setenv("HOME", dir)
	createConfig(t, dir)
	cwd, _ := os.Getwd()
	os.Chdir(work)
	defer os.Chdir(cwd)

	if err := runDeploy(); err != nil {
		t.Fatalf("runDeploy failed: %v", err)
	}
}

func TestRunStatus(t *testing.T) {
	_, cleanup := createFakeCommands(t)
	defer cleanup()
	if err := runStatus(); err != nil {
		t.Fatalf("runStatus failed: %v", err)
	}
}

func TestSetupCmd(t *testing.T) {
	_, cleanup := createFakeCommands(t)
	defer cleanup()
	workDir := t.TempDir()

	cmd := newSetupCmd()
	cmd.Flags().Set("workdir", workDir)
	cmd.SetContext(context.Background())
	if err := cmd.RunE(cmd, []string{}); err != nil {
		t.Fatalf("setup cmd failed: %v", err)
	}
}
