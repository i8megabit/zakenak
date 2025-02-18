# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# Dockerfile for Zakenak

# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY . .

# Установка зависимостей
RUN apk add --no-cache git
RUN go mod download

# Сборка с поддержкой GPU
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -o zakenak ./cmd/zakenak

# Final stage
FROM nvidia/cuda:12.8.0-base-ubuntu22.04

WORKDIR /app
COPY --from=builder /app/zakenak .

# Установка необходимых runtime зависимостей
RUN apt-get update && apt-get install -y \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

# Настройка переменных окружения для NVIDIA
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV PATH="/usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/lib/wsl/lib:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}"

# Создаем entrypoint скрипт
COPY <<EOF /app/entrypoint.sh
#!/bin/bash
set -e

# Настройка Git глобально
git config --global --add safe.directory "*"
git config --global init.defaultBranch main
git config --global user.email "zakenak@local"
git config --global user.name "Zakenak"

cd /workspace

# Проверка и настройка Git репозитория
if [ ! -d .git ]; then
    echo "Initializing new git repository..."
    git init
    git add .
    git commit -m "Initial commit by Zakenak"
    git branch -M main
else
    echo "Git repository exists, ensuring correct branch..."
    # Проверяем существование ветки main
    if git rev-parse --verify main >/dev/null 2>&1; then
        echo "Main branch exists, checking out..."
        git checkout main || {
            echo "Failed to checkout main, attempting to fix..."
            # Сохраняем текущие изменения
            git stash || true
            git checkout -B main
            git stash pop || true
        }
    else
        echo "Main branch does not exist, creating..."
        current_branch=\$(git rev-parse --abbrev-ref HEAD || echo "unknown")
        git checkout -B main
    fi
fi

# Сброс upstream если он установлен
git branch --unset-upstream 2>/dev/null || true

# Запуск основной команды
exec /app/zakenak "\$@"
EOF



RUN chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]